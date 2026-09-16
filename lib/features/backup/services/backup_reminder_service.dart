import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/l10n/current_strings.dart';
import '../../alarm/services/notification_service.dart';
import '../domain/backup_reminder.dart';
import 'auto_backup_settings.dart';

const int backupReminderNotificationId = 900001;

class BackupReminderService {
  final AutoBackupSettings settings;

  BackupReminderService({AutoBackupSettings? settings})
      : settings = settings ?? AutoBackupSettings();

  Future<void> checkAndNotify({DateTime? now}) async {
    final moment = now ?? DateTime.now();
    final firstSeen = settings.ensureFirstSeen();
    final lastRun = settings.lastRun;

    final due = shouldNagAboutBackup(
      lastBackupAt: lastRun,
      firstSeenAt: firstSeen,
      lastNaggedAt: settings.lastNagged,
      now: moment,
    );
    if (!due) return;

    final days = daysSinceLastBackup(
      lastBackupAt: lastRun,
      firstSeenAt: firstSeen,
      now: moment,
    );

    final s = currentStrings();
    await NotificationService.fln.show(
      backupReminderNotificationId,
      s.backup_reminder_title,
      s.backup_reminder_body(days),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'backup_reminders',
          'Pengingat Backup',
          channelDescription: 'Pengingat kalau sudah lama tidak backup data',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    await settings.setLastNagged(moment);
  }
}
