import 'dart:io';

import 'package:asoyy/core/constants/app_constants.dart';
import 'package:asoyy/features/password/data/datasources/password_local_datasource.dart';
import 'package:asoyy/features/password/data/models/password_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

PasswordModel sample(String id, String secret) => PasswordModel(
      id: id,
      title: 'Akun $id',
      username: 'user$id',
      password: secret,
      website: 'https://example.com',
      notes: 'catatan',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  final key = List<int>.generate(32, (i) => i);
  final cipher = HiveAesCipher(key);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vault_test');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PasswordModelAdapter());
    }
    await Hive.openBox(AppConstants.settingsBox);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<List<PasswordModel>> readEncrypted() async {
    final box = await Hive.openBox<PasswordModel>(
      AppConstants.passwordsBox,
      encryptionCipher: cipher,
    );
    final values = box.values.toList();
    await box.close();
    return values;
  }

  test('migrates existing plaintext entries into the encrypted box', () async {
    final plain = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
    await plain.putAll({
      'a': sample('a', 'rahasia-a'),
      'b': sample('b', 'rahasia-b'),
    });
    await plain.close();

    await migratePlaintextVault(cipher);

    final restored = await readEncrypted();
    expect(restored, hasLength(2));
    expect(
      restored.map((p) => p.password).toSet(),
      {'rahasia-a', 'rahasia-b'},
    );
    expect(restored.map((p) => p.title).toSet(), {'Akun a', 'Akun b'});
  });

  test('the migrated box file no longer contains the plaintext secret',
      () async {
    final plain = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
    await plain.put('a', sample('a', 'SUPER-RAHASIA-123'));
    await plain.close();

    final path = '${dir.path}/${AppConstants.passwordsBox}.hive';
    String onDisk() => String.fromCharCodes(File(path).readAsBytesSync());

    expect(
      onDisk(),
      contains('SUPER-RAHASIA-123'),
      reason: 'sanity check: the old format really was plaintext',
    );

    await migratePlaintextVault(cipher);

    expect(onDisk(), isNot(contains('SUPER-RAHASIA-123')));
  });

  test('ensureVaultEncrypted migrates once and sets the flag', () async {
    final plain = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
    await plain.put('a', sample('a', 'rahasia-a'));
    await plain.close();

    expect(isVaultEncrypted(), isFalse);
    await ensureVaultEncrypted(cipher);
    expect(isVaultEncrypted(), isTrue);

    final restored = await readEncrypted();
    expect(restored, hasLength(1));
    expect(restored.single.password, 'rahasia-a');
  });

  test('ensureVaultEncrypted on every launch never wipes the vault', () async {
    final plain = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
    await plain.put('a', sample('a', 'rahasia-a'));
    await plain.close();

    for (var launch = 0; launch < 5; launch++) {
      await ensureVaultEncrypted(cipher);
      final restored = await readEncrypted();
      expect(restored, hasLength(1), reason: 'launch $launch');
      expect(restored.single.password, 'rahasia-a', reason: 'launch $launch');
    }
  });

  test('Hive opens an encrypted box without a cipher as empty, not an error',
      () async {
    final box = await Hive.openBox<PasswordModel>(
      AppConstants.passwordsBox,
      encryptionCipher: cipher,
    );
    await box.put('a', sample('a', 'rahasia-a'));
    await box.close();

    final probed = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
    expect(probed.values, isEmpty);
    await probed.close();
  });

  test('a fresh install with no vault yet migrates to an empty box', () async {
    await migratePlaintextVault(cipher);
    expect(await readEncrypted(), isEmpty);
  });

  test('the wrong key cannot read the migrated vault', () async {
    final plain = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
    await plain.put('a', sample('a', 'rahasia-a'));
    await plain.close();

    await migratePlaintextVault(cipher);

    final wrong = HiveAesCipher(List<int>.generate(32, (i) => 255 - i));
    final box = await Hive.openBox<PasswordModel>(
      AppConstants.passwordsBox,
      encryptionCipher: wrong,
    );
    expect(box.values, isEmpty);
    await box.close();
  });

  group('a missing vault key', () {
    test('is refused instead of silently opening an empty vault', () async {
      final plain = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
      await plain.put('a', sample('a', 'rahasia-a'));
      await plain.close();

      await ensureVaultEncrypted(cipher);
      expect(isVaultEncrypted(), isTrue);

      await expectLater(
        openVaultBox(),
        throwsA(isA<VaultKeyMissingException>()),
        reason: 'no key is reachable in a plain test environment',
      );
    });

    test('leaves the encrypted data on disk untouched', () async {
      final plain = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
      await plain.put('a', sample('a', 'rahasia-a'));
      await plain.close();
      await ensureVaultEncrypted(cipher);

      try {
        await openVaultBox();
      } catch (_) {}

      final restored = await readEncrypted();
      expect(restored, hasLength(1));
      expect(restored.single.password, 'rahasia-a');
    });

    test('the unreadable datasource refuses reads and writes', () async {
      final ds = UnreadableVaultDatasource();
      await expectLater(
        ds.getPasswords(),
        throwsA(isA<VaultKeyMissingException>()),
      );
      await expectLater(
        ds.savePassword(sample('a', 'x')),
        throwsA(isA<VaultKeyMissingException>()),
        reason: 'writing would corrupt the vault it cannot read',
      );
      await expectLater(
        ds.deletePassword('a'),
        throwsA(isA<VaultKeyMissingException>()),
      );
    });

    test('resetVault clears the box, the flag and starts fresh', () async {
      final plain = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
      await plain.put('a', sample('a', 'rahasia-a'));
      await plain.close();
      await ensureVaultEncrypted(cipher);

      await resetVault();

      expect(isVaultEncrypted(), isFalse);
      final box = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
      expect(box.values, isEmpty);
      await box.close();
    });
  });
}
