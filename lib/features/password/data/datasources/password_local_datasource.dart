import 'dart:io';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../services/vault_key_store.dart';
import '../models/password_model.dart';

class VaultKeyMissingException implements Exception {
  const VaultKeyMissingException();
  @override
  String toString() => 'vault-key-missing';
}

abstract class PasswordLocalDatasource {
  Future<List<PasswordModel>> getPasswords();
  Future<void> savePassword(PasswordModel password);
  Future<void> deletePassword(String id);
}

class PasswordLocalDatasourceImpl implements PasswordLocalDatasource {
  final Box<PasswordModel> box;
  PasswordLocalDatasourceImpl(this.box);

  static Future<PasswordLocalDatasource> create() async {
    try {
      return PasswordLocalDatasourceImpl(await openVaultBox());
    } on VaultKeyMissingException {
      return UnreadableVaultDatasource();
    }
  }

  @override
  Future<List<PasswordModel>> getPasswords() async => box.values.toList();

  @override
  Future<void> savePassword(PasswordModel password) =>
      box.put(password.id, password);

  @override
  Future<void> deletePassword(String id) => box.delete(id);
}

class UnreadableVaultDatasource implements PasswordLocalDatasource {
  @override
  Future<List<PasswordModel>> getPasswords() async =>
      throw const VaultKeyMissingException();

  @override
  Future<void> savePassword(PasswordModel password) async =>
      throw const VaultKeyMissingException();

  @override
  Future<void> deletePassword(String id) async =>
      throw const VaultKeyMissingException();
}

const String vaultEncryptedFlag = 'vault_encrypted';

bool isVaultEncrypted() =>
    Hive.box(AppConstants.settingsBox).get(vaultEncryptedFlag) == true;

Future<void> setVaultEncrypted(bool value) =>
    Hive.box(AppConstants.settingsBox).put(vaultEncryptedFlag, value);

Future<void> ensureVaultEncrypted(HiveAesCipher cipher) async {
  if (isVaultEncrypted()) return;
  await migratePlaintextVault(cipher);
}

Future<Box<PasswordModel>> openVaultBox() async {
  final store = VaultKeyStore();
  final existing = await store.read();

  if (existing == null && isVaultEncrypted()) {
    throw const VaultKeyMissingException();
  }

  final cipher = HiveAesCipher(existing ?? await store.readOrCreate());
  await ensureVaultEncrypted(cipher);

  if (Hive.isBoxOpen(AppConstants.passwordsBox)) {
    return Hive.box<PasswordModel>(AppConstants.passwordsBox);
  }
  return Hive.openBox<PasswordModel>(
    AppConstants.passwordsBox,
    encryptionCipher: cipher,
  );
}

Future<void> resetVault() async {
  if (Hive.isBoxOpen(AppConstants.passwordsBox)) {
    await Hive.box<PasswordModel>(AppConstants.passwordsBox).close();
  }
  await Hive.deleteBoxFromDisk(AppConstants.passwordsBox);
  await VaultKeyStore().delete();
  await setVaultEncrypted(false);
}

PasswordModel _detach(PasswordModel p) => PasswordModel(
      id: p.id,
      title: p.title,
      username: p.username,
      password: p.password,
      website: p.website,
      notes: p.notes,
      createdAt: p.createdAt,
    );

Future<void> _closeVaultBox() async {
  if (Hive.isBoxOpen(AppConstants.passwordsBox)) {
    await Hive.box<PasswordModel>(AppConstants.passwordsBox).close();
  }
}

Future<List<PasswordModel>> _readPlaintextVault() async {
  final box = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
  final entries = box.values.map(_detach).toList(growable: false);
  await box.close();
  return entries;
}

Future<void> migratePlaintextVault(HiveAesCipher cipher) async {
  await _closeVaultBox();

  final String? boxPath;
  List<PasswordModel> rescued;
  try {
    final probe = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
    boxPath = probe.path;
    rescued = probe.values.map(_detach).toList(growable: false);
    await probe.close();
  } catch (_) {
    return;
  }
  if (boxPath == null) return;

  final live = File(boxPath);
  final holding = File('$boxPath.pre_encrypt');

  if (rescued.isEmpty && holding.existsSync()) {
    if (live.existsSync()) await live.delete();
    await holding.rename(boxPath);
    rescued = await _readPlaintextVault();
  }

  if (live.existsSync()) {
    if (holding.existsSync()) await holding.delete();
    await live.rename(holding.path);
  }
  await Hive.deleteBoxFromDisk(AppConstants.passwordsBox);

  final encrypted = await Hive.openBox<PasswordModel>(
    AppConstants.passwordsBox,
    encryptionCipher: cipher,
  );
  await encrypted.putAll({for (final p in rescued) p.id: p});
  await encrypted.flush();
  final written = encrypted.length;
  await encrypted.close();

  if (written != rescued.length) {
    await Hive.deleteBoxFromDisk(AppConstants.passwordsBox);
    if (holding.existsSync()) await holding.rename(boxPath);
    throw StateError('vault migration wrote $written of ${rescued.length}');
  }

  await setVaultEncrypted(true);
  if (holding.existsSync()) await holding.delete();
}
