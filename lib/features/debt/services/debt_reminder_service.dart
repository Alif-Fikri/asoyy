import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/di/injection_container.dart' as di;
import '../../alarm/services/notification_service.dart';
import '../../notifications/data/notification_mute_repository.dart';
import '../../split_bill/domain/repositories/split_bill_repository.dart';
import '../domain/entities/debt_entity.dart';
import '../domain/repositories/debt_repository.dart';
import '../domain/utils/debt_reminder_schedule.dart';

int notificationIdForDebt(String sourceId) => sourceId.hashCode.abs() % 100000;

int notificationIdForDueSoon(String sourceId) =>
    (sourceId.hashCode.abs() % 100000) + 500000;

class DebtReminderService {
  final _muteRepo = NotificationMuteRepository();

  static final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> _schedule(String sourceId, DateTime since, String body) async {
    final id = notificationIdForDebt(sourceId);
    await NotificationService.fln.cancel(id);

    if (_muteRepo.isMuted(sourceId)) return;

    final now = DateTime.now();
    final reminderTime = nextDebtReminderTime(since, now);

    await NotificationService.fln.zonedSchedule(
      id,
      'Pengingat Utang Piutang',
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_reminders',
          'Pengingat Utang Piutang',
          channelDescription: 'Pengingat berkala untuk utang/piutang yang belum lunas',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String sourceId) async {
    await NotificationService.fln.cancel(notificationIdForDebt(sourceId));
    await NotificationService.fln.cancel(notificationIdForDueSoon(sourceId));
  }

  Future<void> _scheduleDueSoon(String sourceId, DateTime dueDate, String body) async {
    final id = notificationIdForDueSoon(sourceId);
    await NotificationService.fln.cancel(id);

    if (_muteRepo.isMuted(sourceId)) return;
    if (!shouldNotifyDueSoon(dueDate, DateTime.now())) return;

    await NotificationService.fln.zonedSchedule(
      id,
      'Jatuh Tempo Besok',
      body,
      tz.TZDateTime.from(dueSoonReminderTime(dueDate), tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_due_soon',
          'Jatuh Tempo Besok',
          channelDescription: 'Peringatan sehari sebelum utang/piutang jatuh tempo',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> rescheduleAll() async {
    final now = DateTime.now();

    final debtRepo = di.sl<DebtRepository>();
    for (final debt in await debtRepo.getDebts()) {
      final sourceId = 'debt-${debt.id}';
      if (debt.isSettled) {
        await cancelReminder(sourceId);
        continue;
      }
      final anchor = debt.reminderAnchor;
      final days = daysSince(anchor, now);
      final overdue = debt.dueDate != null && now.isAfter(anchor);
      final suffix = overdue ? '$days hari lewat jatuh tempo' : '$days hari';
      final body = debt.direction == DebtDirection.theyOweMe
          ? '${debt.personName} belum bayar ${_fmt.format(debt.amount)} ($suffix)'
          : 'Kamu belum bayar ${debt.personName} ${_fmt.format(debt.amount)} ($suffix)';
      await _schedule(sourceId, anchor, body);

      if (debt.dueDate != null) {
        final dueSoonBody = debt.direction == DebtDirection.theyOweMe
            ? '${debt.personName} jatuh tempo besok, ${_fmt.format(debt.amount)}'
            : 'Utangmu ke ${debt.personName} jatuh tempo besok, ${_fmt.format(debt.amount)}';
        await _scheduleDueSoon(sourceId, debt.dueDate!, dueSoonBody);
      } else {
        await NotificationService.fln.cancel(notificationIdForDueSoon(sourceId));
      }
    }

    final billRepo = di.sl<SplitBillRepository>();
    for (final bill in await billRepo.getBills()) {
      for (final p in bill.participants) {
        final sourceId = 'bill-${bill.id}-${p.id}';
        if (p.isPaid) {
          await cancelReminder(sourceId);
          continue;
        }
        final days = daysSince(bill.date, now);
        final body =
            '${p.name} belum bayar ${_fmt.format(p.amount)} dari \'${bill.title}\' ($days hari)';
        await _schedule(sourceId, bill.date, body);
      }
    }
  }
}
