import 'package:hive/hive.dart';
import '../../domain/entities/note_entity.dart';

part 'note_model.g.dart';

@HiveType(typeId: 9)
class ChecklistItemModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final bool isDone;

  ChecklistItemModel({
    required this.id,
    required this.text,
    required this.isDone,
  });

  factory ChecklistItemModel.fromEntity(ChecklistItem e) => ChecklistItemModel(
        id: e.id,
        text: e.text,
        isDone: e.isDone,
      );

  ChecklistItem toEntity() =>
      ChecklistItem(id: id, text: text, isDone: isDone);
}

@HiveType(typeId: 8)
class NoteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? body;

  @HiveField(3)
  final List<ChecklistItemModel> items;

  @HiveField(4)
  final DateTime? dueDate;

  @HiveField(5)
  final DateTime? remindAt;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final bool isDone;

  NoteModel({
    required this.id,
    required this.title,
    this.body,
    required this.items,
    this.dueDate,
    this.remindAt,
    required this.createdAt,
    required this.isDone,
  });

  factory NoteModel.fromEntity(NoteEntity e) => NoteModel(
        id: e.id,
        title: e.title,
        body: e.body,
        items: e.items.map(ChecklistItemModel.fromEntity).toList(),
        dueDate: e.dueDate,
        remindAt: e.remindAt,
        createdAt: e.createdAt,
        isDone: e.isDone,
      );

  NoteEntity toEntity() => NoteEntity(
        id: id,
        title: title,
        body: body,
        items: items.map((i) => i.toEntity()).toList(growable: false),
        dueDate: dueDate,
        remindAt: remindAt,
        createdAt: createdAt,
        isDone: isDone,
      );
}
