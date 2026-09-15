class ChecklistItem {
  final String id;
  final String text;
  final bool isDone;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  ChecklistItem copyWith({String? text, bool? isDone}) => ChecklistItem(
        id: id,
        text: text ?? this.text,
        isDone: isDone ?? this.isDone,
      );
}

class NoteEntity {
  final String id;
  final String title;
  final String? body;
  final List<ChecklistItem> items;
  final DateTime? dueDate;
  final DateTime? remindAt;
  final DateTime createdAt;
  final bool isDone;

  const NoteEntity({
    required this.id,
    required this.title,
    this.body,
    this.items = const [],
    this.dueDate,
    this.remindAt,
    required this.createdAt,
    this.isDone = false,
  });

  bool get isChecklist => items.isNotEmpty;

  bool get hasDeadline => dueDate != null;

  bool get hasReminder => remindAt != null;

  int get doneCount => items.where((i) => i.isDone).length;

  bool get allItemsDone => isChecklist && doneCount == items.length;

  bool get isCompleted => isChecklist ? allItemsDone : isDone;

  double get progress =>
      isChecklist ? doneCount / items.length : (isDone ? 1 : 0);

  NoteEntity copyWith({
    String? title,
    String? body,
    List<ChecklistItem>? items,
    DateTime? dueDate,
    DateTime? remindAt,
    bool clearDueDate = false,
    bool clearRemindAt = false,
    bool? isDone,
  }) =>
      NoteEntity(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        items: items ?? this.items,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        remindAt: clearRemindAt ? null : (remindAt ?? this.remindAt),
        createdAt: createdAt,
        isDone: isDone ?? this.isDone,
      );
}
