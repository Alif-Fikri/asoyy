import 'package:equatable/equatable.dart';
import '../../data/indonesian_holidays.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/holiday_entity.dart';

abstract class CalendarState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<EventEntity> events;
  final List<HolidayEntity> holidays;
  final int? paydayDay;
  final DateTime selectedDay;
  final DateTime focusedDay;

  CalendarLoaded({
    required this.events,
    required this.selectedDay,
    required this.focusedDay,
    List<HolidayEntity>? holidays,
    this.paydayDay,
  }) : holidays = holidays ?? IndonesianHolidays.all;

  List<EventEntity> get eventsForSelectedDay => events
      .where((e) =>
          e.date.year == selectedDay.year &&
          e.date.month == selectedDay.month &&
          e.date.day == selectedDay.day)
      .toList();

  List<HolidayEntity> get holidaysForSelectedDay => holidays
      .where((h) =>
          h.date.year == selectedDay.year &&
          h.date.month == selectedDay.month &&
          h.date.day == selectedDay.day)
      .toList();

  bool get isPaydaySelected =>
      paydayDay != null && selectedDay.day == paydayDay;

  Map<DateTime, List<EventEntity>> get eventMap {
    final map = <DateTime, List<EventEntity>>{};
    for (final e in events) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      (map[key] ??= []).add(e);
    }
    return map;
  }

  Map<DateTime, List<HolidayEntity>> get holidayMap {
    final map = <DateTime, List<HolidayEntity>>{};
    for (final h in holidays) {
      final key = DateTime(h.date.year, h.date.month, h.date.day);
      (map[key] ??= []).add(h);
    }
    return map;
  }

  CalendarLoaded copyWith({
    List<EventEntity>? events,
    List<HolidayEntity>? holidays,
    int? Function()? paydayDay,
    DateTime? selectedDay,
    DateTime? focusedDay,
  }) =>
      CalendarLoaded(
        events: events ?? this.events,
        holidays: holidays ?? this.holidays,
        paydayDay: paydayDay != null ? paydayDay() : this.paydayDay,
        selectedDay: selectedDay ?? this.selectedDay,
        focusedDay: focusedDay ?? this.focusedDay,
      );

  @override
  List<Object?> get props => [events, holidays, paydayDay, selectedDay, focusedDay];
}

class CalendarError extends CalendarState {
  final String message;
  CalendarError(this.message);
  @override
  List<Object?> get props => [message];
}
