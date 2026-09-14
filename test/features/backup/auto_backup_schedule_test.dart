import 'package:asoyy/features/backup/domain/auto_backup_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 14, 12);

  group('isBackupDue', () {
    test('never runs while it is switched off', () {
      expect(
        isBackupDue(
          enabled: false,
          frequency: BackupFrequency.daily,
          lastRun: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('runs immediately when it has never run', () {
      expect(
        isBackupDue(
          enabled: true,
          frequency: BackupFrequency.weekly,
          lastRun: null,
          now: now,
        ),
        isTrue,
      );
    });

    test('waits out the interval', () {
      expect(
        isBackupDue(
          enabled: true,
          frequency: BackupFrequency.daily,
          lastRun: now.subtract(const Duration(hours: 23)),
          now: now,
        ),
        isFalse,
      );
      expect(
        isBackupDue(
          enabled: true,
          frequency: BackupFrequency.daily,
          lastRun: now.subtract(const Duration(hours: 25)),
          now: now,
        ),
        isTrue,
      );
    });

    test('each frequency waits its own interval', () {
      bool due(BackupFrequency f, int days) => isBackupDue(
            enabled: true,
            frequency: f,
            lastRun: now.subtract(Duration(days: days)),
            now: now,
          );

      expect(due(BackupFrequency.weekly, 6), isFalse);
      expect(due(BackupFrequency.weekly, 8), isTrue);
      expect(due(BackupFrequency.monthly, 29), isFalse);
      expect(due(BackupFrequency.monthly, 31), isTrue);
    });

    test('a clock moved backwards does not stall backups forever', () {
      expect(
        isBackupDue(
          enabled: true,
          frequency: BackupFrequency.monthly,
          lastRun: now.add(const Duration(days: 400)),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('nextBackupAt', () {
    test('is one interval after the last run', () {
      expect(
        nextBackupAt(
          enabled: true,
          frequency: BackupFrequency.weekly,
          lastRun: DateTime(2026, 9, 1),
        ),
        DateTime(2026, 9, 8),
      );
    });

    test('is unknown when it is off or has never run', () {
      expect(
        nextBackupAt(
          enabled: false,
          frequency: BackupFrequency.daily,
          lastRun: now,
        ),
        isNull,
      );
      expect(
        nextBackupAt(
          enabled: true,
          frequency: BackupFrequency.daily,
          lastRun: null,
        ),
        isNull,
      );
    });
  });

  group('frequencyFromName', () {
    test('round trips every value', () {
      for (final f in BackupFrequency.values) {
        expect(frequencyFromName(f.name), f);
      }
    });

    test('falls back to weekly for anything unknown', () {
      expect(frequencyFromName(null), BackupFrequency.weekly);
      expect(frequencyFromName('yearly'), BackupFrequency.weekly);
    });
  });

  group('backupsToDelete', () {
    List<String> files(int count) =>
        List.generate(count, (i) => 'beres-auto-$i.bkp');

    test('keeps everything while under the limit', () {
      expect(backupsToDelete(files(keptBackupCount)), isEmpty);
      expect(backupsToDelete(const []), isEmpty);
    });

    test('drops only the oldest beyond the limit', () {
      final all = files(keptBackupCount + 3);
      final doomed = backupsToDelete(all);

      expect(doomed, hasLength(3));
      expect(doomed, all.sublist(keptBackupCount));
      for (final kept in all.take(keptBackupCount)) {
        expect(doomed, isNot(contains(kept)));
      }
    });
  });
}
