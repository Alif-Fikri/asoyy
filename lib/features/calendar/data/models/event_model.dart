import 'package:hive/hive.dart';
import '../../domain/entities/event_entity.dart';

part 'event_model.g.dart';

@HiveType(typeId: 0)
class EventModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final int colorValue;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.colorValue,
  });

  factory EventModel.fromEntity(EventEntity entity) => EventModel(
        id: entity.id,
        title: entity.title,
        description: entity.description,
        date: entity.date,
        colorValue: entity.colorValue,
      );

  EventEntity toEntity() => EventEntity(
        id: id,
        title: title,
        description: description,
        date: date,
        colorValue: colorValue,
      );
}
