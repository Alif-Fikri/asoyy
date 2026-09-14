import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../services/vault_key_store.dart';
import '../models/password_model.dart';

abstract class PasswordLocalDatasource {
  Future<List<PasswordModel>> getPasswords();
  Future<void> savePassword(PasswordModel password);
  Future<void> deletePassword(String id);
}

class PasswordLocalDatasourceImpl implements PasswordLocalDatasource {
  final Box<PasswordModel> box;
  PasswordLocalDatasourceImpl(this.box);

  static Future<PasswordLocalDatasourceImpl> create() async {
    final box = await openVaultBox();
    return PasswordLocalDatasourceImpl(box);
  }

  @override
  Future<List<PasswordModel>> getPasswords() async => box.values.toList();

  @override
  Future<void> savePassword(PasswordModel password) =>
      box.put(password.id, password);

  @override
  Future<void> deletePassword(String id) => box.delete(id);
}

const String vaultEncryptedFlag = 'vault_encrypted';

bool isVaultEncrypted() =>
    Hive.box(AppConstants.settingsBox).get(vaultEncryptedFlag) == true;

Future<void> setVaultEncrypted(bool value) =>
    Hive.box(AppConstants.settingsBox).put(vaultEncryptedFlag, value);

/// Migrates the vault exactly once, then records that it is encrypted.
///
/// The flag is what makes this safe to call on every launch: [migratePlaintextVault]
/// is destructive if the vault is already encrypted, so it must never run twice.
Future<void> ensureVaultEncrypted(HiveAesCipher cipher) async {
  if (isVaultEncrypted()) return;
  await migratePlaintextVault(cipher);
  await setVaultEncrypted(true);
}

Future<Box<PasswordModel>> openVaultBox() async {
  final cipher = HiveAesCipher(await VaultKeyStore().readOrCreate());
  await ensureVaultEncrypted(cipher);

  if (Hive.isBoxOpen(AppConstants.passwordsBox)) {
    return Hive.box<PasswordModel>(AppConstants.passwordsBox);
  }
  return Hive.openBox<PasswordModel>(
    AppConstants.passwordsBox,
    encryptionCipher: cipher,
  );
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

/// Rewrites a plaintext vault as an encrypted one.
///
/// Only ever call this when the vault is known to still be plaintext: Hive
/// opens an encrypted box without a cipher as an *empty* box rather than
/// failing, so probing would silently destroy an already encrypted vault.
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
