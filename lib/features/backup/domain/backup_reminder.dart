const Duration backupReminderInterval = Duration(days: 14);

bool shouldNagAboutBackup({
  required DateTime? lastBackupAt,
  required DateTime firstSeenAt,
  required DateTime? lastNaggedAt,
  required DateTime now,
  Duration interval = backupReminderInterval,
}) {
  final anchor = lastBackupAt ?? firstSeenAt;
  if (now.difference(anchor) < interval) return false;
  if (lastNaggedAt != null && now.difference(lastNaggedAt) < interval) return false;
  return true;
}

int daysSinceLastBackup({
  required DateTime? lastBackupAt,
  required DateTime firstSeenAt,
  required DateTime now,
}) {
  final anchor = lastBackupAt ?? firstSeenAt;
  return now.difference(anchor).inDays;
}
