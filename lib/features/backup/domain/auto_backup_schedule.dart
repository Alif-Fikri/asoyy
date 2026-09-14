enum BackupFrequency { daily, weekly, monthly }

Duration intervalFor(BackupFrequency frequency) {
  switch (frequency) {
    case BackupFrequency.daily:
      return const Duration(days: 1);
    case BackupFrequency.weekly:
      return const Duration(days: 7);
    case BackupFrequency.monthly:
      return const Duration(days: 30);
  }
}

bool isBackupDue({
  required bool enabled,
  required BackupFrequency frequency,
  required DateTime? lastRun,
  required DateTime now,
}) {
  if (!enabled) return false;
  if (lastRun == null) return true;
  if (lastRun.isAfter(now)) return true;
  return now.difference(lastRun) >= intervalFor(frequency);
}

DateTime? nextBackupAt({
  required bool enabled,
  required BackupFrequency frequency,
  required DateTime? lastRun,
}) {
  if (!enabled) return null;
  if (lastRun == null) return null;
  return lastRun.add(intervalFor(frequency));
}

BackupFrequency frequencyFromName(String? raw) {
  for (final f in BackupFrequency.values) {
    if (f.name == raw) return f;
  }
  return BackupFrequency.weekly;
}

const int keptBackupCount = 5;

List<String> backupsToDelete(List<String> sortedNewestFirst) =>
    sortedNewestFirst.length <= keptBackupCount
        ? const []
        : sortedNewestFirst.sublist(keptBackupCount);
