import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/constants/app_constants.dart';
import '../../alarm/services/notification_service.dart';
import '../../notifications/data/notification_mute_repository.dart';
import '../data/recurring_transaction_repository.dart';
import '../domain/entities/recurring_transaction_entity.dart';
import '../domain/utils/recurring_schedule.dart';

const _actionMarkPaid = 'recurring_mark_paid';
const _actionSnooze = 'recurring_snooze';
const _categoryId = 'recurring_reminder';

final recurringReminderIosCategory = DarwinNotificationCategory(
  _categoryId,
  actions: [
    DarwinNotificationAction.plain(_actionMarkPaid, 'Tandai Lunas'),
    DarwinNotificationAction.plain(_actionSnooze, 'Tunda 4 Jam'),
  ],
);

int notificationIdForRecurring(String recurringId) =>
    recurringId.hashCode.abs() % 100000;

class RecurringReminderService {
  final _repo = RecurringTransactionRepository();
  final _muteRepo = NotificationMuteRepository();

  Future<void> scheduleReminder(RecurringTransactionEntity item) async {
    final id = notificationIdForRecurring(item.id);
    await NotificationService.fln.cancel(id);

    if (_muteRepo.isMuted(item.id)) return;

    final now = DateTime.now();
    final reminderTime = nextReminderTime(item, now);
    if (reminderTime.isBefore(now)) return;

    await NotificationService.fln.zonedSchedule(
      id,
      'Tagihan Berulang Besok',
      '${item.title} sebesar Rp${item.amount.toStringAsFixed(0)} akan otomatis tercatat besok.',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'recurring_reminders',
          'Pengingat Transaksi Berulang',
          channelDescription: 'Pengingat H-1 sebelum tagihan berulang tercatat',
          importance: Importance.high,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction(_actionMarkPaid, 'Tandai Lunas'),
            AndroidNotificationAction(_actionSnooze, 'Tunda 4 Jam'),
          ],
        ),
        iOS: const DarwinNotificationDetails(categoryIdentifier: _categoryId),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '${item.id}|$id',
    );
  }

  Future<void> cancelReminder(String recurringId) async {
    await NotificationService.fln.cancel(notificationIdForRecurring(recurringId));
  }

  Future<void> rescheduleAll() async {
    for (final item in _repo.getAll()) {
      await scheduleReminder(item);
    }
  }
}

Future<void> _handleAction(NotificationResponse response) async {
  final actionId = response.actionId;
  final payload = response.payload;
  if (actionId == null || payload == null) return;

  if (!Hive.isBoxOpen(AppConstants.settingsBox)) {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.settingsBox);
  }

  final parts = payload.split('|');
  final recurringId = parts.first;
  final repo = RecurringTransactionRepository();
  final items = repo.getAll();
  final item = items.where((e) => e.id == recurringId).cast<RecurringTransactionEntity?>().firstOrNull;
  if (item == null) return;

  if (actionId == _actionMarkPaid) {
    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await repo.markSkipped(recurringId, currentMonthKey);
    await NotificationService.fln.cancel(notificationIdForRecurring(recurringId));
  } else if (actionId == _actionSnooze) {
    final id = notificationIdForRecurring(recurringId);
    final snoozeTime = DateTime.now().add(const Duration(hours: 4));
    await NotificationService.fln.zonedSchedule(
      id,
      'Tagihan Berulang Besok',
      '${item.title} sebesar Rp${item.amount.toStringAsFixed(0)} akan otomatis tercatat besok.',
      tz.TZDateTime.from(snoozeTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'recurring_reminders',
          'Pengingat Transaksi Berulang',
          channelDescription: 'Pengingat H-1 sebelum tagihan berulang tercatat',
          importance: Importance.high,
          priority: Priority.high,
          actions: const [
            AndroidNotificationAction(_actionMarkPaid, 'Tandai Lunas'),
            AndroidNotificationAction(_actionSnooze, 'Tunda 4 Jam'),
          ],
        ),
        iOS: const DarwinNotificationDetails(categoryIdentifier: _categoryId),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}

void handleRecurringReminderResponse(NotificationResponse response) {
  _handleAction(response);
}

@pragma('vm:entry-point')
void handleRecurringReminderResponseBackground(NotificationResponse response) {
  _handleAction(response);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
