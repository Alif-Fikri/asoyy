import 'package:asoyy/core/constants/app_constants.dart';
import 'package:asoyy/features/password/data/datasources/password_local_datasource.dart';
import 'package:asoyy/features/password/data/models/password_model.dart';
import 'package:asoyy/features/password/services/vault_key_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

PasswordModel sample(String id, String secret) => PasswordModel(
      id: id,
      title: 'Akun $id',
      username: 'user$id',
      password: secret,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PasswordModelAdapter());
    }
  });

  setUp(() async {
    if (!Hive.isBoxOpen(AppConstants.settingsBox)) {
      await Hive.openBox(AppConstants.settingsBox);
    }
    await resetVault();
  });

  tearDown(() async {
    await resetVault();
  });

  testWidgets('losing the key is detected instead of showing an empty vault',
      (tester) async {
    final box = await openVaultBox();
    await box.put('a', sample('a', 'SANDI-ASLI'));
    await box.flush();
    await box.close();

    expect(isVaultEncrypted(), isTrue);
    expect(await VaultKeyStore().read(), isNotNull);

    await VaultKeyStore().delete();

    await expectLater(
      openVaultBox(),
      throwsA(isA<VaultKeyMissingException>()),
    );

    final ds = await PasswordLocalDatasourceImpl.create();
    expect(ds, isA<UnreadableVaultDatasource>());
    await expectLater(
      ds.getPasswords(),
      throwsA(isA<VaultKeyMissingException>()),
    );
    await expectLater(
      ds.savePassword(sample('b', 'baru')),
      throwsA(isA<VaultKeyMissingException>()),
    );
  });

  testWidgets('resetting recovers a usable vault', (tester) async {
    final box = await openVaultBox();
    await box.put('a', sample('a', 'SANDI-ASLI'));
    await box.flush();
    await box.close();
    await VaultKeyStore().delete();

    await resetVault();

    expect(isVaultEncrypted(), isFalse);
    final ds = await PasswordLocalDatasourceImpl.create();
    expect(ds, isA<PasswordLocalDatasourceImpl>());
    expect(await ds.getPasswords(), isEmpty);

    await ds.savePassword(sample('c', 'sandi-baru'));
    final after = await ds.getPasswords();
    expect(after.single.password, 'sandi-baru');
  });

  testWidgets('a healthy vault opens and reads back normally', (tester) async {
    final box = await openVaultBox();
    await box.put('a', sample('a', 'SANDI-ASLI'));
    await box.flush();
    await box.close();

    final ds = await PasswordLocalDatasourceImpl.create();
    expect(ds, isA<PasswordLocalDatasourceImpl>());
    final list = await ds.getPasswords();
    expect(list.single.password, 'SANDI-ASLI');
  });
}
