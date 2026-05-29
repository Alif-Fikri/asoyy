class AlarmEntity {
  final String id;
  final String label;
  final int hour;
  final int minute;
  final List<int> days;
  final bool isEnabled;

  const AlarmEntity({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    required this.days,
    required this.isEnabled,
  });

  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String daysString(List<String> dayNames, String once, String everyday) {
    if (days.isEmpty) return once;
    if (days.length == 7) return everyday;
    return days.map((d) => dayNames[d - 1]).join(', ');
  }

  AlarmEntity copyWith({bool? isEnabled}) => AlarmEntity(
        id: id,
        label: label,
        hour: hour,
        minute: minute,
        days: days,
        isEnabled: isEnabled ?? this.isEnabled,
      );
}
