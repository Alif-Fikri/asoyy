import 'package:asoyy/features/notes/domain/entities/note_entity.dart';
import 'package:asoyy/features/notes/domain/utils/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

NoteEntity note({
  String id = 'n1',
  String title = 'Catatan',
  List<ChecklistItem> items = const [],
  DateTime? due,
  DateTime? remind,
  bool done = false,
  DateTime? created,
}) =>
    NoteEntity(
      id: id,
      title: title,
      items: items,
      dueDate: due,
      remindAt: remind,
      isDone: done,
      createdAt: created ?? DateTime(2026, 9, 1),
    );

ChecklistItem item(String id, {bool done = false}) =>
    ChecklistItem(id: id, text: id, isDone: done);

void main() {
  final now = DateTime(2026, 9, 15, 10);

  group('completion', () {
    test('a plain note is done only when marked done', () {
      expect(note().isCompleted, isFalse);
      expect(note(done: true).isCompleted, isTrue);
    });

    test('a checklist is done when every item is ticked', () {
      expect(note(items: [item('a'), item('b')]).isCompleted, isFalse);
      expect(
        note(items: [item('a', done: true), item('b')]).isCompleted,
        isFalse,
      );
      expect(
        note(items: [item('a', done: true), item('b', done: true)]).isCompleted,
        isTrue,
      );
    });

    test('progress reflects how much is ticked', () {
      expect(note(items: [item('a'), item('b')]).progress, 0);
      expect(
        note(items: [item('a', done: true), item('b')]).progress,
        0.5,
      );
      expect(note(done: true).progress, 1);
      expect(note().progress, 0);
    });

    test('an empty item list is a plain note, not a checklist', () {
      expect(note().isChecklist, isFalse);
      expect(note(items: [item('a')]).isChecklist, isTrue);
    });
  });

  group('urgencyOf', () {
    test('a note with no deadline is never urgent', () {
      expect(urgencyOf(note(), now), NoteUrgency.none);
    });

    test('reads yesterday, today and tomorrow', () {
      expect(
        urgencyOf(note(due: DateTime(2026, 9, 14)), now),
        NoteUrgency.overdue,
      );
      expect(
        urgencyOf(note(due: DateTime(2026, 9, 15)), now),
        NoteUrgency.dueToday,
      );
      expect(
        urgencyOf(note(due: DateTime(2026, 9, 16)), now),
        NoteUrgency.upcoming,
      );
    });

    test('a deadline earlier today still counts as due today', () {
      expect(
        urgencyOf(note(due: DateTime(2026, 9, 15, 8)), now),
        NoteUrgency.dueToday,
      );
    });

    test('a finished note is never overdue', () {
      expect(
        urgencyOf(note(due: DateTime(2026, 9, 1), done: true), now),
        NoteUrgency.none,
      );
      expect(
        urgencyOf(
          note(due: DateTime(2026, 9, 1), items: [item('a', done: true)]),
          now,
        ),
        NoteUrgency.none,
      );
    });
  });

  group('daysUntilDue', () {
    test('counts forward and backward', () {
      expect(daysUntilDue(note(due: DateTime(2026, 9, 18)), now), 3);
      expect(daysUntilDue(note(due: DateTime(2026, 9, 15)), now), 0);
      expect(daysUntilDue(note(due: DateTime(2026, 9, 12)), now), -3);
    });
  });

  group('sortNotes', () {
    test('overdue first, then due today, then the rest, done last', () {
      final sorted = sortNotes([
        note(id: 'done', due: DateTime(2026, 9, 1), done: true),
        note(id: 'later', due: DateTime(2026, 9, 20)),
        note(id: 'overdue', due: DateTime(2026, 9, 10)),
        note(id: 'today', due: DateTime(2026, 9, 15)),
      ], now);

      expect(sorted.map((n) => n.id), ['overdue', 'today', 'later', 'done']);
    });

    test('notes with a deadline come before those without', () {
      final sorted = sortNotes([
        note(id: 'no-deadline'),
        note(id: 'deadline', due: DateTime(2026, 9, 20)),
      ], now);

      expect(sorted.first.id, 'deadline');
    });

    test('newest first when nothing else separates them', () {
      final sorted = sortNotes([
        note(id: 'old', created: DateTime(2026, 9, 1)),
        note(id: 'new', created: DateTime(2026, 9, 10)),
      ], now);

      expect(sorted.map((n) => n.id), ['new', 'old']);
    });

    test('does not modify the list it was given', () {
      final original = [
        note(id: 'a', due: DateTime(2026, 9, 20)),
        note(id: 'b', due: DateTime(2026, 9, 10)),
      ];
      sortNotes(original, now);
      expect(original.map((n) => n.id), ['a', 'b']);
    });
  });

  group('nextNoteReminder', () {
    test('is null without a reminder', () {
      expect(nextNoteReminder(note(), now), isNull);
    });

    test('returns a reminder still ahead', () {
      final at = DateTime(2026, 9, 16, 9);
      expect(nextNoteReminder(note(remind: at), now), at);
    });

    test('drops a reminder that has passed', () {
      expect(
        nextNoteReminder(note(remind: DateTime(2026, 9, 14, 9)), now),
        isNull,
      );
    });

    test('drops the reminder once the note is finished', () {
      expect(
        nextNoteReminder(
          note(remind: DateTime(2026, 9, 16, 9), done: true),
          now,
        ),
        isNull,
      );
    });
  });
}
