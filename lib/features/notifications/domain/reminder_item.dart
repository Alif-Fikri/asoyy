import 'package:flutter/material.dart';
import '../../alarm/domain/entities/alarm_entity.dart';
import '../../alarm/services/alarm_schedule.dart';
import '../../calendar/domain/entities/event_entity.dart';
import '../../calendar/domain/entities/holiday_entity.dart';

enum ReminderKind { alarm, event, holiday, payday }

class ReminderItem {
  final ReminderKind kind;
  final String id;
  final String title;
  final DateTime when;
  final Color color;
  final bool hasTime;

  const ReminderItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.when,
    required this.color,
    this.hasTime = true,
  });
}

DateTime? nextPayday(int? paydayDay, DateTime now) {
  if (paydayDay == null) return null;
  var year = now.year;
  var month = now.month;
  DateTime build(int y, int m) {
    final lastDay = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, paydayDay > lastDay ? lastDay : paydayDay);
  }

  var date = build(year, month);
  if (date.isBefore(DateTime(now.year, now.month, now.day))) {
    month += 1;
    if (month > 12) {
      month = 1;
      year += 1;
    }
    date = build(year, month);
  }
  return date;
}

List<ReminderItem> buildReminders({
  required List<AlarmEntity> alarms,
  required List<EventEntity> events,
  required List<HolidayEntity> holidays,
  required int? paydayDay,
  required DateTime now,
  required Color alarmColor,
  required Color holidayColor,
  required Color paydayColor,
  required String paydayLabel,
  required bool isId,
  int horizonDays = 60,
}) {
  final horizon = now.add(Duration(days: horizonDays));
  final items = <ReminderItem>[];

  for (final alarm in alarms) {
    final when = nextAlarmOccurrence(alarm, now);
    if (when == null || when.isAfter(horizon)) continue;
    items.add(ReminderItem(
      kind: ReminderKind.alarm,
      id: alarm.id,
      title: alarm.label.isNotEmpty ? alarm.label : alarm.timeString,
      when: when,
      color: alarmColor,
    ));
  }

  final today = DateTime(now.year, now.month, now.day);
  for (final event in events) {
    if (event.date.isBefore(today) || event.date.isAfter(horizon)) continue;
    items.add(ReminderItem(
      kind: ReminderKind.event,
      id: event.id,
      title: event.title,
      when: event.date,
      color: event.color,
      hasTime: false,
    ));
  }

  for (final holiday in holidays) {
    if (holiday.date.isBefore(today) || holiday.date.isAfter(horizon)) continue;
    items.add(ReminderItem(
      kind: ReminderKind.holiday,
      id: 'holiday-${holiday.date.toIso8601String()}',
      title: isId ? holiday.nameId : holiday.nameEn,
      when: holiday.date,
      color: holidayColor,
      hasTime: false,
    ));
  }

  final payday = nextPayday(paydayDay, now);
  if (payday != null && !payday.isAfter(horizon)) {
    items.add(ReminderItem(
      kind: ReminderKind.payday,
      id: 'payday',
      title: paydayLabel,
      when: payday,
      color: paydayColor,
      hasTime: false,
    ));
  }

  items.sort((a, b) => a.when.compareTo(b.when));
  return items;
}
