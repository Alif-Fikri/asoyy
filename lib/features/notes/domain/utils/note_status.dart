import '../entities/note_entity.dart';

enum NoteUrgency { none, upcoming, dueToday, overdue }

NoteUrgency urgencyOf(NoteEntity note, DateTime now) {
  final due = note.dueDate;
  if (due == null || note.isCompleted) return NoteUrgency.none;

  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(due.year, due.month, due.day);

  if (dueDay.isBefore(today)) return NoteUrgency.overdue;
  if (dueDay == today) return NoteUrgency.dueToday;
  return NoteUrgency.upcoming;
}

int daysUntilDue(NoteEntity note, DateTime now) {
  final due = note.dueDate;
  if (due == null) return 0;
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(due.year, due.month, due.day);
  return dueDay.difference(today).inDays;
}

List<NoteEntity> sortNotes(List<NoteEntity> notes, DateTime now) {
  int rank(NoteEntity note) {
    if (note.isCompleted) return 3;
    switch (urgencyOf(note, now)) {
      case NoteUrgency.overdue:
        return 0;
      case NoteUrgency.dueToday:
        return 1;
      case NoteUrgency.upcoming:
      case NoteUrgency.none:
        return 2;
    }
  }

  final sorted = [...notes];
  sorted.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;

    final aDue = a.dueDate;
    final bDue = b.dueDate;
    if (aDue != null && bDue != null) {
      final byDue = aDue.compareTo(bDue);
      if (byDue != 0) return byDue;
    } else if (aDue != null) {
      return -1;
    } else if (bDue != null) {
      return 1;
    }

    return b.createdAt.compareTo(a.createdAt);
  });
  return sorted;
}

DateTime? nextNoteReminder(NoteEntity note, DateTime now) {
  final remindAt = note.remindAt;
  if (remindAt == null) return null;
  if (note.isCompleted) return null;
  if (!remindAt.isAfter(now)) return null;
  return remindAt;
}
