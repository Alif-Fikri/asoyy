import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/backup/domain/backup_reminder.dart';

void main() {
  final now = DateTime(2026, 9, 16);

  group('shouldNagAboutBackup', () {
    test('does not nag when the last backup is recent', () {
      final result = shouldNagAboutBackup(
        lastBackupAt: now.subtract(const Duration(days: 3)),
        firstSeenAt: now.subtract(const Duration(days: 60)),
        lastNaggedAt: null,
        now: now,
      );
      expect(result, isFalse);
    });

    test('nags once the last backup is older than the interval', () {
      final result = shouldNagAboutBackup(
        lastBackupAt: now.subtract(const Duration(days: 15)),
        firstSeenAt: now.subtract(const Duration(days: 60)),
        lastNaggedAt: null,
        now: now,
      );
      expect(result, isTrue);
    });

    test('a backup exactly at the interval boundary already counts as due', () {
      final result = shouldNagAboutBackup(
        lastBackupAt: now.subtract(backupReminderInterval),
        firstSeenAt: now.subtract(const Duration(days: 60)),
        lastNaggedAt: null,
        now: now,
      );
      expect(result, isTrue);
    });

    test('a user who has never backed up is measured from first seen', () {
      final result = shouldNagAboutBackup(
        lastBackupAt: null,
        firstSeenAt: now.subtract(const Duration(days: 20)),
        lastNaggedAt: null,
        now: now,
      );
      expect(result, isTrue);
    });

    test('a brand new install is not nagged immediately', () {
      final result = shouldNagAboutBackup(
        lastBackupAt: null,
        firstSeenAt: now,
        lastNaggedAt: null,
        now: now,
      );
      expect(result, isFalse);
    });

    test('does not nag twice within the same interval', () {
      final result = shouldNagAboutBackup(
        lastBackupAt: now.subtract(const Duration(days: 30)),
        firstSeenAt: now.subtract(const Duration(days: 90)),
        lastNaggedAt: now.subtract(const Duration(days: 2)),
        now: now,
      );
      expect(result, isFalse);
    });

    test('nags again once a full interval has passed since the last nag', () {
      final result = shouldNagAboutBackup(
        lastBackupAt: now.subtract(const Duration(days: 40)),
        firstSeenAt: now.subtract(const Duration(days: 90)),
        lastNaggedAt: now.subtract(const Duration(days: 15)),
        now: now,
      );
      expect(result, isTrue);
    });

    test('a fresh backup silences the nag even if one fired recently', () {
      final justBackedUp = shouldNagAboutBackup(
        lastBackupAt: now,
        firstSeenAt: now.subtract(const Duration(days: 90)),
        lastNaggedAt: now.subtract(const Duration(days: 30)),
        now: now,
      );
      expect(justBackedUp, isFalse);
    });
  });

  group('daysSinceLastBackup', () {
    test('counts from the last backup when one exists', () {
      expect(
        daysSinceLastBackup(
          lastBackupAt: now.subtract(const Duration(days: 7)),
          firstSeenAt: now.subtract(const Duration(days: 90)),
          now: now,
        ),
        7,
      );
    });

    test('counts from first seen when there is no backup yet', () {
      expect(
        daysSinceLastBackup(
          lastBackupAt: null,
          firstSeenAt: now.subtract(const Duration(days: 5)),
          now: now,
        ),
        5,
      );
    });
  });
}
