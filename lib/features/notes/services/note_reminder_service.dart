import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../alarm/services/notification_service.dart';
import '../domain/entities/note_entity.dart';
import '../domain/utils/note_status.dart';

int notificationIdForNote(String noteId) =>
    100000 + (noteId.hashCode.abs() % 100000);

class NoteReminderService {
  final String channelTitle;

  const NoteReminderService({this.channelTitle = 'Pengingat Catatan'});

  Future<void> cancel(String noteId) =>
      NotificationService.fln.cancel(notificationIdForNote(noteId));

  Future<void> schedule(NoteEntity note, {DateTime? now}) async {
    await cancel(note.id);

    final at = nextNoteReminder(note, now ?? DateTime.now());
    if (at == null) return;

    await NotificationService.fln.zonedSchedule(
      notificationIdForNote(note.id),
      channelTitle,
      note.title,
      tz.TZDateTime.from(at, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'note_reminders',
          'Pengingat Catatan',
          channelDescription: 'Pengingat untuk catatan dan checklist',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> rescheduleAll(List<NoteEntity> notes, {DateTime? now}) async {
    for (final note in notes) {
      await schedule(note, now: now);
    }
  }
}
