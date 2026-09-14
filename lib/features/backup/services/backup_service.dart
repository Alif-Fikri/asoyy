import 'dart:io';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../alarm/data/models/alarm_model.dart';
import '../../calendar/data/models/event_model.dart';
import '../../debt/data/models/debt_model.dart';
import '../../finance/data/models/transaction_model.dart';
import '../../password/data/datasources/password_local_datasource.dart';
import '../../password/data/models/password_model.dart';
import '../../password/services/vault_key_store.dart';
import '../../split_bill/data/models/bill_model.dart';
import 'backup_crypto.dart';

const _magic = [0x42, 0x52, 0x53, 0x42];
const _version = 2;

const _vaultKeyEntry = '__vault_key__';

class BackupException implements Exception {
  final String message;
  BackupException(this.message);
  @override
  String toString() => message;
}

class BackupService {
  BoxBase _openBox(String name) {
    switch (name) {
      case AppConstants.eventsBox:
        return Hive.box<EventModel>(name);
      case AppConstants.alarmsBox:
        return Hive.box<AlarmModel>(name);
      case AppConstants.passwordsBox:
        return Hive.box<PasswordModel>(name);
      case AppConstants.transactionsBox:
        return Hive.box<TransactionModel>(name);
      case AppConstants.billsBox:
        return Hive.box<BillModel>(name);
      case AppConstants.debtsBox:
        return Hive.box<DebtModel>(name);
      default:
        return Hive.box(name);
    }
  }

  static const _boxNames = [
    AppConstants.eventsBox,
    AppConstants.alarmsBox,
    AppConstants.passwordsBox,
    AppConstants.transactionsBox,
    AppConstants.billsBox,
    AppConstants.debtsBox,
    AppConstants.settingsBox,
  ];

  Map<String, String?> _boxPaths() => {
        for (final name in _boxNames) name: _openBox(name).path,
      };

  Future<void> _flushAll() async {
    for (final name in _boxNames) {
      await _openBox(name).flush();
    }
  }

  Future<File> createBackup(String passphrase) async {
    await _flushAll();
    final paths = _boxPaths();

    final payload = <String, Uint8List>{};
    for (final entry in paths.entries) {
      final path = entry.value;
      payload[entry.key] = (path != null && File(path).existsSync())
          ? await File(path).readAsBytes()
          : Uint8List(0);
    }

    final vaultKey = await VaultKeyStore().read();
    if (vaultKey != null) payload[_vaultKeyEntry] = vaultKey;

    final container = BytesBuilder();
    container.addByte(payload.length);
    for (final entry in payload.entries) {
      final nameBytes = entry.key.codeUnits;
      container.add(_u16(nameBytes.length));
      container.add(nameBytes);
      container.add(_u32(entry.value.length));
      container.add(entry.value);
    }

    final salt = randomBytes(backupSaltLength);
    final iv = randomBytes(backupIvLength);
    final key = deriveKey(passphrase, salt);
    final cipher = encryptBytes(container.toBytes(), key, iv);

    final out = BytesBuilder();
    out.add(_magic);
    out.addByte(_version);
    out.add(salt);
    out.add(iv);
    out.add(cipher);

    final tempDir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final file = File('${tempDir.path}/beres-backup-$stamp.bkp');
    await file.writeAsBytes(out.toBytes());
    return file;
  }

  Future<void> restoreBackup(File file, String passphrase) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 4 + 1 + backupSaltLength + backupIvLength ||
        !_matchesMagic(bytes)) {
      throw BackupException('File backup tidak valid.');
    }

    var offset = 4;
    offset += 1;
    final salt = bytes.sublist(offset, offset + backupSaltLength);
    offset += backupSaltLength;
    final iv = bytes.sublist(offset, offset + backupIvLength);
    offset += backupIvLength;
    final cipher = bytes.sublist(offset);

    final key = deriveKey(passphrase, Uint8List.fromList(salt));
    late Uint8List plain;
    try {
      plain = decryptBytes(Uint8List.fromList(cipher), key, Uint8List.fromList(iv));
    } catch (_) {
      throw BackupException('Passphrase salah atau file rusak.');
    }

    final entries = <String, Uint8List>{};
    try {
      var pos = 0;
      final boxCount = plain[pos];
      pos += 1;
      for (var i = 0; i < boxCount; i++) {
        final nameLen = _readU16(plain, pos);
        pos += 2;
        final name = String.fromCharCodes(plain.sublist(pos, pos + nameLen));
        pos += nameLen;
        final dataLen = _readU32(plain, pos);
        pos += 4;
        final data = plain.sublist(pos, pos + dataLen);
        pos += dataLen;
        entries[name] = data;
      }
    } catch (_) {
      throw BackupException('Passphrase salah atau file rusak.');
    }

    final paths = _boxPaths();
    for (final entry in entries.entries) {
      final path = paths[entry.key];
      if (path == null) continue;
      if (Hive.isBoxOpen(entry.key)) {
        await _openBox(entry.key).close();
      }
      await File(path).writeAsBytes(entry.value, flush: true);
    }

    await _restoreVault(entries[_vaultKeyEntry]);
  }

  /// Re-points the vault at the restored data.
  ///
  /// A v2 archive carries the key the restored box file was encrypted with, so
  /// the vault stays readable on a different device. A v1 archive holds a
  /// plaintext box, which is encrypted on the spot instead.
  Future<void> _restoreVault(Uint8List? backedUpKey) async {
    if (!Hive.isBoxOpen(AppConstants.settingsBox)) {
      await Hive.openBox(AppConstants.settingsBox);
    }
    final store = VaultKeyStore();

    if (backedUpKey != null && backedUpKey.length == vaultKeyLength) {
      await store.write(backedUpKey);
      await setVaultEncrypted(true);
      return;
    }

    await setVaultEncrypted(false);
    await ensureVaultEncrypted(HiveAesCipher(await store.readOrCreate()));
  }

  bool _matchesMagic(Uint8List bytes) {
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) return false;
    }
    return true;
  }

  List<int> _u16(int value) => [(value >> 8) & 0xff, value & 0xff];

  List<int> _u32(int value) => [
        (value >> 24) & 0xff,
        (value >> 16) & 0xff,
        (value >> 8) & 0xff,
        value & 0xff,
      ];

  int _readU16(Uint8List bytes, int offset) =>
      (bytes[offset] << 8) | bytes[offset + 1];

  int _readU32(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
