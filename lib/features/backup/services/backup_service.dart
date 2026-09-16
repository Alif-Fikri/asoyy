import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../alarm/data/models/alarm_model.dart';
import '../../calendar/data/models/event_model.dart';
import '../../debt/data/models/debt_model.dart';
import '../../finance/data/models/account_model.dart';
import '../../finance/data/models/transaction_model.dart';
import '../../notes/data/models/note_model.dart';
import '../../password/data/datasources/password_local_datasource.dart';
import '../../password/data/models/password_model.dart';
import '../../password/services/vault_key_store.dart';
import '../domain/vault_restore_plan.dart';
import '../../split_bill/data/models/bill_model.dart';
import 'backup_crypto.dart';

const _magic = [0x42, 0x52, 0x53, 0x42];
const _version = 3;

const _vaultKeyEntry = '__vault_key__';
const _vaultStateEntry = '__vault_encrypted__';

class BackupRestoreResult {
  final bool vaultKeyMissing;

  const BackupRestoreResult({required this.vaultKeyMissing});
}

class BackupException implements Exception {
  final String message;
  BackupException(this.message);
  @override
  String toString() => message;
}

class _KeyMaterial {
  final Uint8List encryptionKey;
  final Uint8List macKey;

  const _KeyMaterial({required this.encryptionKey, required this.macKey});
}

class _DeriveRequest {
  final String passphrase;
  final Uint8List salt;
  final int iterations;

  const _DeriveRequest(this.passphrase, this.salt, this.iterations);
}

Uint8List _deriveInIsolate(_DeriveRequest request) => deriveKey(
      request.passphrase,
      request.salt,
      iterations: request.iterations,
      length: 64,
    );

Future<_KeyMaterial> _deriveMaterial({
  required String passphrase,
  required Uint8List salt,
  required int iterations,
}) async {
  final bytes = await compute(
    _deriveInIsolate,
    _DeriveRequest(passphrase, salt, iterations),
  );
  return _KeyMaterial(
    encryptionKey: Uint8List.fromList(bytes.sublist(0, 32)),
    macKey: Uint8List.fromList(bytes.sublist(32, 64)),
  );
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
      case AppConstants.accountsBox:
        return Hive.box<AccountModel>(name);
      case AppConstants.notesBox:
        return Hive.box<NoteModel>(name);
      default:
        return Hive.box(name);
    }
  }

  static const _boxNames = AppConstants.allDataBoxes;

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

    final vaultWasEncrypted = isVaultEncrypted();
    final vaultKey = await VaultKeyStore().read();

    if (vaultWasEncrypted && vaultKey == null) {
      throw BackupException(
        'Kunci vault password tidak terbaca, jadi backup ini tidak akan bisa '
        'membuka vault-mu lagi. Buka menu Password dulu untuk memastikan '
        'vault masih bisa diakses, lalu coba backup lagi.',
      );
    }

    if (vaultKey != null) payload[_vaultKeyEntry] = vaultKey;
    payload[_vaultStateEntry] = Uint8List.fromList([vaultWasEncrypted ? 1 : 0]);

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
    final material = await _deriveMaterial(
      passphrase: passphrase,
      salt: salt,
      iterations: backupPbkdf2Iterations,
    );
    final cipher = encryptBytes(container.toBytes(), material.encryptionKey, iv);

    final header = <int>[
      ..._magic,
      _version,
      ..._u32(backupPbkdf2Iterations),
      ...salt,
      ...iv,
    ];
    final tag = computeBackupTag(
      macKey: material.macKey,
      header: header,
      cipher: cipher,
    );

    final out = BytesBuilder();
    out.add(header);
    out.add(cipher);
    out.add(tag);

    final tempDir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final file = File('${tempDir.path}/beres-backup-$stamp.bkp');
    await file.writeAsBytes(out.toBytes());
    return file;
  }

  Future<BackupRestoreResult> restoreBackup(File file, String passphrase) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 4 + 1 + backupSaltLength + backupIvLength ||
        !_matchesMagic(bytes)) {
      throw BackupException('File backup tidak valid.');
    }

    var offset = 4;
    final fileVersion = bytes[offset];
    offset += 1;
    if (fileVersion < 1 || fileVersion > _version) {
      throw BackupException(
        'File backup ini dibuat versi aplikasi yang lebih baru. '
        'Perbarui aplikasinya dulu.',
      );
    }

    final isAuthenticated = fileVersion >= 3;

    final int iterations;
    if (isAuthenticated) {
      iterations = _readU32(bytes, offset);
      offset += 4;
    } else {
      iterations = legacyBackupPbkdf2Iterations;
    }

    final salt = bytes.sublist(offset, offset + backupSaltLength);
    offset += backupSaltLength;
    final iv = bytes.sublist(offset, offset + backupIvLength);
    offset += backupIvLength;

    final Uint8List cipher;
    if (isAuthenticated) {
      if (bytes.length < offset + backupTagLength) {
        throw BackupException('File backup tidak valid.');
      }
      cipher = bytes.sublist(offset, bytes.length - backupTagLength);
    } else {
      cipher = bytes.sublist(offset);
    }

    final material = await _deriveMaterial(
      passphrase: passphrase,
      salt: Uint8List.fromList(salt),
      iterations: iterations,
    );

    if (isAuthenticated) {
      final expected = computeBackupTag(
        macKey: material.macKey,
        header: bytes.sublist(0, offset),
        cipher: cipher,
      );
      final actual = bytes.sublist(bytes.length - backupTagLength);
      if (!constantTimeEquals(expected, actual)) {
        throw BackupException(
          'Passphrase salah, atau file backup ini sudah berubah sejak dibuat.',
        );
      }
    }

    late Uint8List plain;
    try {
      plain = decryptBytes(cipher, material.encryptionKey, Uint8List.fromList(iv));
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

    return _restoreVault(
      backedUpKey: entries[_vaultKeyEntry],
      vaultState: entries[_vaultStateEntry],
    );
  }

  Future<BackupRestoreResult> _restoreVault({
    required Uint8List? backedUpKey,
    required Uint8List? vaultState,
  }) async {
    if (!Hive.isBoxOpen(AppConstants.settingsBox)) {
      await Hive.openBox(AppConstants.settingsBox);
    }
    final store = VaultKeyStore();

    final plan = planVaultRestore(
      backedUpKey: backedUpKey,
      vaultState: vaultState,
      expectedKeyLength: vaultKeyLength,
    );

    switch (plan) {
      case VaultRestorePlan.useBackedUpKey:
        await store.write(backedUpKey!);
        await setVaultEncrypted(true);
        return const BackupRestoreResult(vaultKeyMissing: false);

      case VaultRestorePlan.keepLocked:
        await store.delete();
        await setVaultEncrypted(true);
        return const BackupRestoreResult(vaultKeyMissing: true);

      case VaultRestorePlan.migratePlaintext:
        await setVaultEncrypted(false);
        await ensureVaultEncrypted(HiveAesCipher(await store.readOrCreate()));
        return const BackupRestoreResult(vaultKeyMissing: false);
    }
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
