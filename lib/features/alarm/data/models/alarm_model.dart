import 'package:hive/hive.dart';
import '../../domain/entities/alarm_entity.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 1)
class AlarmModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final int hour;

  @HiveField(3)
  final int minute;

  @HiveField(4)
  final List<int> days;

  @HiveField(5)
  final bool isEnabled;

  @HiveField(6)
  final String? soundPath;

  @HiveField(7)
  final String? soundName;

  AlarmModel({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    required this.days,
    required this.isEnabled,
    this.soundPath,
    this.soundName,
  });

  factory AlarmModel.fromEntity(AlarmEntity e) => AlarmModel(
        id: e.id,
        label: e.label,
        hour: e.hour,
        minute: e.minute,
        days: List<int>.from(e.days),
        isEnabled: e.isEnabled,
        soundPath: e.soundPath,
        soundName: e.soundName,
      );

  AlarmEntity toEntity() => AlarmEntity(
        id: id,
        label: label,
        hour: hour,
        minute: minute,
        days: List<int>.from(days),
        isEnabled: isEnabled,
        soundPath: soundPath,
        soundName: soundName,
      );
}
