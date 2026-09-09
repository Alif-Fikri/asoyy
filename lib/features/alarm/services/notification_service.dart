import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../finance/services/recurring_reminder_service.dart';
import '../domain/entities/alarm_entity.dart';
import 'alarm_schedule.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static final FlutterLocalNotificationsPlugin fln =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await fln.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          notificationCategories: [recurringReminderIosCategory],
        ),
      ),
      onDidReceiveNotificationResponse: handleRecurringReminderResponse,
      onDidReceiveBackgroundNotificationResponse:
          handleRecurringReminderResponseBackground,
    );
    await fln.cancelAll();

    await fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await Alarm.init();
  }

  Future<void> scheduleAlarm(AlarmEntity alarm, {String stopButtonText = 'Stop'}) async {
    await cancelAlarm(alarm.id);
    if (!alarm.isEnabled) return;

    final baseId = alarm.id.hashCode.abs() % 100000;
    final settings = _buildSettings(
      id: baseId,
      alarm: alarm,
      stopButtonText: stopButtonText,
    );

    if (alarm.days.isEmpty) {
      await Alarm.set(alarmSettings: settings);
    } else {
      for (final day in alarm.days) {
        await Alarm.set(
          alarmSettings: settings.copyWith(
            id: (baseId + day) % 100000,
            dateTime: nextOccurrence(alarm.hour, alarm.minute, day),
          ),
        );
      }
    }
  }

  Future<void> cancelAlarm(String alarmId) async {
    final id = alarmId.hashCode.abs() % 100000;
    await Alarm.stop(id);
    for (int day = 1; day <= 7; day++) {
      await Alarm.stop((id + day) % 100000);
    }
  }

  AlarmSettings _buildSettings({
    required int id,
    required AlarmEntity alarm,
    required String stopButtonText,
  }) {
    return AlarmSettings(
      id: id,
      dateTime: nextOccurrence(alarm.hour, alarm.minute, null),
      assetAudioPath: 'assets/audio/alarm.wav',
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      warningNotificationOnKill: true,
      androidStopAlarmOnTermination: false,
      volumeSettings: VolumeSettings.fade(
        fadeDuration: const Duration(seconds: 5),
        volume: 1.0,
        volumeEnforced: false,
        showSystemUI: false,
      ),
      notificationSettings: NotificationSettings(
        title: alarm.label,
        body: _formatTime(alarm.hour, alarm.minute),
        stopButton: stopButtonText,
      ),
    );
  }

  String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
