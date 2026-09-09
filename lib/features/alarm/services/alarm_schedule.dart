import '../domain/entities/alarm_entity.dart';

DateTime nextOccurrence(int hour, int minute, int? weekday, [DateTime? from]) {
  final now = from ?? DateTime.now();
  var date = DateTime(now.year, now.month, now.day, hour, minute);
  if (!date.isAfter(now)) date = date.add(const Duration(days: 1));
  if (weekday != null) {
    while (date.weekday != weekday) {
      date = date.add(const Duration(days: 1));
    }
  }
  return date;
}

DateTime? nextAlarmOccurrence(AlarmEntity alarm, [DateTime? from]) {
  if (!alarm.isEnabled) return null;
  final now = from ?? DateTime.now();
  if (alarm.days.isEmpty) {
    return nextOccurrence(alarm.hour, alarm.minute, null, now);
  }
  final candidates = alarm.days
      .map((d) => nextOccurrence(alarm.hour, alarm.minute, d, now))
      .toList()
    ..sort();
  return candidates.first;
}
