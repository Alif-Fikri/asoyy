import 'dart:convert';
import 'dart:io';

import 'package:asoyy/core/constants/app_constants.dart';
import 'package:asoyy/features/password/data/auth_config_repository.dart';
import 'package:asoyy/features/password/domain/entities/auth_method.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;
  late AuthConfigRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('auth_test');
    Hive.init(dir.path);
    await Hive.openBox(AppConstants.settingsBox);
    repo = AuthConfigRepository();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Box settings() => Hive.box(AppConstants.settingsBox);

  group('setMethod and verify', () {
    test('accepts the right PIN and rejects the wrong one', () async {
      await repo.setMethod(AuthMethod.pin, secret: '123456');
      expect(await repo.verify('123456'), isTrue);
      expect(await repo.verify('123457'), isFalse);
      expect(await repo.verify(''), isFalse);
    });

    test('works the same for a pattern', () async {
      await repo.setMethod(AuthMethod.pattern, secret: '0-1-2-5-8');
      expect(await repo.verify('0-1-2-5-8'), isTrue);
      expect(await repo.verify('0-1-2-5-7'), isFalse);
    });

    test('the stored digest is not a bare SHA-256 of the PIN', () async {
      await repo.setMethod(AuthMethod.pin, secret: '123456');
      final legacy = sha256.convert(utf8.encode('123456')).toString();
      expect(settings().get('auth_hash'), isNot(legacy));
    });

    test('the same PIN on two devices yields different digests', () async {
      await repo.setMethod(AuthMethod.pin, secret: '123456');
      final first = settings().get('auth_hash');
      await repo.setMethod(AuthMethod.pin, secret: '123456');
      expect(settings().get('auth_hash'), isNot(first),
          reason: 'a random salt must make the digest unique');
    });

    test('biometric clears any stored secret', () async {
      await repo.setMethod(AuthMethod.pin, secret: '123456');
      await repo.setMethod(AuthMethod.biometric);
      expect(settings().get('auth_hash'), isNull);
      expect(settings().get('auth_salt'), isNull);
      expect(await repo.verify('123456'), isFalse);
    });

    test('a secret is required for PIN and pattern', () async {
      expect(
        () => repo.setMethod(AuthMethod.pin),
        throwsArgumentError,
      );
    });

    test('verify is false when nothing is configured', () async {
      expect(await repo.verify('123456'), isFalse);
    });

    test('clear removes the method, digest and salt', () async {
      await repo.setMethod(AuthMethod.pin, secret: '123456');
      await repo.clear();
      expect(repo.isConfigured, isFalse);
      expect(settings().get('auth_hash'), isNull);
      expect(settings().get('auth_salt'), isNull);
    });
  });

  group('legacy upgrade', () {
    Future<void> seedLegacy(String secret) async {
      await settings().put('auth_method', AuthMethod.pin.name);
      await settings().put('auth_hash',
          sha256.convert(utf8.encode(secret)).toString());
      await settings().delete('auth_salt');
    }

    test('an existing unsalted PIN still unlocks', () async {
      await seedLegacy('123456');
      expect(await repo.verify('123456'), isTrue);
    });

    test('a wrong PIN against a legacy digest is still rejected', () async {
      await seedLegacy('123456');
      expect(await repo.verify('999999'), isFalse);
      expect(settings().get('auth_salt'), isNull,
          reason: 'a failed attempt must not rewrite the stored secret');
    });

    test('unlocking upgrades the stored digest in place', () async {
      await seedLegacy('123456');
      final before = settings().get('auth_hash');

      expect(await repo.verify('123456'), isTrue);

      expect(settings().get('auth_salt'), isNotNull);
      expect(settings().get('auth_hash'), isNot(before));
      expect(await repo.verify('123456'), isTrue, reason: 'still unlocks after upgrade');
      expect(await repo.verify('999999'), isFalse);
    });
  });

  group('cost', () {
    test('a verify takes long enough to blunt brute force', () async {
      await repo.setMethod(AuthMethod.pin, secret: '123456');
      final sw = Stopwatch()..start();
      await repo.verify('123456');
      sw.stop();
      expect(sw.elapsedMilliseconds, greaterThan(20),
          reason: 'derivation must not be instant');
    });
  });
}
