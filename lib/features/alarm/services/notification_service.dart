import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/constants/app_constants.dart';
import '../domain/entities/alarm_entity.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _batteryChannel = MethodChannel('com.example.asoyy/battery');

  Future<void> init() async {

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    try {
      await _batteryChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {
    }
  }

  Future<void> scheduleAlarm(AlarmEntity alarm) async {
    await cancelAlarm(alarm.id);
    if (!alarm.isEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      sound: const RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      playSound: true,
    );

    final details = NotificationDetails(android: androidDetails);
    final id = alarm.id.hashCode.abs() % 100000;

    if (alarm.days.isEmpty) {
      await _plugin.zonedSchedule(
        id,
        '${AppConstants.appName} — ${alarm.label}',
        alarm.timeString,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      for (final day in alarm.days) {
        var dayScheduled = scheduled;
        while (dayScheduled.weekday != day) {
          dayScheduled = dayScheduled.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          (id + day) % 100000,
          '${AppConstants.appName} — ${alarm.label}',
          alarm.timeString,
          dayScheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  Future<void> cancelAlarm(String alarmId) async {
    final id = alarmId.hashCode.abs() % 100000;
    await _plugin.cancel(id);
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel((id + day) % 100000);
    }
  }
}
