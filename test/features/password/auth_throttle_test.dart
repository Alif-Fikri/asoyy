import 'dart:io';

import 'package:asoyy/core/constants/app_constants.dart';
import 'package:asoyy/features/password/data/auth_throttle_repository.dart';
import 'package:asoyy/features/password/domain/auth_throttle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  group('lockoutForFailures', () {
    test('the first few attempts are free', () {
      for (var i = 0; i <= authFreeAttempts; i++) {
        expect(lockoutForFailures(i), Duration.zero, reason: '$i gagal');
      }
    });

    test('each further failure costs more', () {
      final ladder = [
        lockoutForFailures(authFreeAttempts + 1),
        lockoutForFailures(authFreeAttempts + 2),
        lockoutForFailures(authFreeAttempts + 3),
        lockoutForFailures(authFreeAttempts + 4),
      ];
      expect(ladder, [
        const Duration(seconds: 30),
        const Duration(minutes: 1),
        const Duration(minutes: 5),
        const Duration(minutes: 15),
      ]);
      for (var i = 1; i < ladder.length; i++) {
        expect(ladder[i], greaterThan(ladder[i - 1]));
      }
    });

    test('the delay plateaus instead of growing forever', () {
      expect(lockoutForFailures(50), const Duration(minutes: 30));
      expect(lockoutForFailures(500), lockoutForFailures(50));
    });

    test('a thousand guesses cost hours, not seconds', () {
      var total = Duration.zero;
      for (var i = 1; i <= 1000; i++) {
        total += lockoutForFailures(i);
      }
      expect(total.inHours, greaterThan(8));
    });
  });

  group('attemptsLeftBeforeLockout', () {
    test('counts down and never goes negative', () {
      expect(attemptsLeftBeforeLockout(0), authFreeAttempts);
      expect(attemptsLeftBeforeLockout(authFreeAttempts - 1), 1);
      expect(attemptsLeftBeforeLockout(authFreeAttempts), 0);
      expect(attemptsLeftBeforeLockout(authFreeAttempts + 10), 0);
    });
  });

  group('formatLockout', () {
    test('renders seconds, minutes and both', () {
      expect(formatLockout(const Duration(seconds: 30)), '30s');
      expect(formatLockout(const Duration(minutes: 5)), '5m');
      expect(formatLockout(const Duration(minutes: 1, seconds: 30)), '1m 30s');
      expect(formatLockout(const Duration(seconds: -5)), '0s');
    });
  });

  group('AuthThrottleRepository', () {
    late Directory dir;
    late AuthThrottleRepository repo;
    final now = DateTime(2026, 6, 15, 10);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('throttle_test');
      Hive.init(dir.path);
      await Hive.openBox(AppConstants.settingsBox);
      repo = AuthThrottleRepository();
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('starts clean', () {
      expect(repo.failures, 0);
      expect(repo.isLockedOut(now), isFalse);
      expect(repo.remainingLockout(now), Duration.zero);
    });

    test('free attempts do not lock anything', () async {
      for (var i = 0; i < authFreeAttempts; i++) {
        expect(await repo.registerFailure(now), Duration.zero);
      }
      expect(repo.failures, authFreeAttempts);
      expect(repo.isLockedOut(now), isFalse);
    });

    test('the next failure starts a lockout', () async {
      for (var i = 0; i < authFreeAttempts; i++) {
        await repo.registerFailure(now);
      }
      final lockout = await repo.registerFailure(now);

      expect(lockout, const Duration(seconds: 30));
      expect(repo.isLockedOut(now), isTrue);
      expect(repo.remainingLockout(now), const Duration(seconds: 30));
    });

    test('the lockout expires on its own', () async {
      for (var i = 0; i <= authFreeAttempts; i++) {
        await repo.registerFailure(now);
      }
      expect(repo.isLockedOut(now.add(const Duration(seconds: 29))), isTrue);
      expect(repo.isLockedOut(now.add(const Duration(seconds: 31))), isFalse);
      expect(repo.remainingLockout(now.add(const Duration(minutes: 5))),
          Duration.zero);
    });

    test('a success clears the record', () async {
      for (var i = 0; i <= authFreeAttempts; i++) {
        await repo.registerFailure(now);
      }
      await repo.reset();

      expect(repo.failures, 0);
      expect(repo.isLockedOut(now), isFalse);
    });

    test('the count survives a restart, so closing the app is no escape',
        () async {
      for (var i = 0; i <= authFreeAttempts; i++) {
        await repo.registerFailure(now);
      }
      await Hive.close();

      Hive.init(dir.path);
      await Hive.openBox(AppConstants.settingsBox);
      final reopened = AuthThrottleRepository();

      expect(reopened.failures, authFreeAttempts + 1);
      expect(reopened.isLockedOut(now), isTrue);
    });

    test('failures keep stacking across lockouts', () async {
      for (var i = 0; i < authFreeAttempts + 2; i++) {
        await repo.registerFailure(now);
      }
      expect(repo.failures, authFreeAttempts + 2);
      expect(repo.remainingLockout(now), const Duration(minutes: 1));
    });
  });
}
