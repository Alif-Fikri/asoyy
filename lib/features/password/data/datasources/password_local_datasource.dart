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
  await setVaultEncrypted(true);
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

Future<void> migratePlaintextVault(HiveAesCipher cipher) async {
  if (Hive.isBoxOpen(AppConstants.passwordsBox)) {
    await Hive.box<PasswordModel>(AppConstants.passwordsBox).close();
  }

  final List<PasswordModel> rescued;
  try {
    final plain = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
    rescued = plain.values.map(_detach).toList(growable: false);
    await plain.close();
  } catch (_) {
    return;
  }

  await Hive.deleteBoxFromDisk(AppConstants.passwordsBox);

  final encrypted = await Hive.openBox<PasswordModel>(
    AppConstants.passwordsBox,
    encryptionCipher: cipher,
  );
  await encrypted.putAll({for (final p in rescued) p.id: p});
  await encrypted.flush();
  await encrypted.close();
}
