import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../../services/note_reminder_service.dart';
import 'note_event.dart';
import 'note_state.dart';

class NoteBloc extends Bloc<NoteBlocEvent, NoteState> {
  final NoteRepository repository;
  final NoteReminderService reminderService;

  NoteBloc({required this.repository, required this.reminderService})
      : super(NoteInitial()) {
    on<LoadNotes>(_onLoad);
    on<SaveNoteRequested>(_onSave);
    on<DeleteNoteRequested>(_onDelete);
    on<ToggleChecklistItemRequested>(_onToggleItem);
    on<ToggleNoteDoneRequested>(_onToggleDone);
  }

  Future<void> _onLoad(LoadNotes event, Emitter<NoteState> emit) async {
    emit(NoteLoading());
    try {
      final notes = await repository.getNotes();
      emit(NoteLoaded(notes));
      await reminderService.rescheduleAll(notes);
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }

  Future<void> _onSave(SaveNoteRequested event, Emitter<NoteState> emit) async {
    await repository.saveNote(event.note);
    await reminderService.schedule(event.note);
    if (state is! NoteLoaded) return;

    final current = state as NoteLoaded;
    final exists = current.notes.any((n) => n.id == event.note.id);
    final updated = exists
        ? current.notes
            .map((n) => n.id == event.note.id ? event.note : n)
            .toList()
        : [event.note, ...current.notes];
    emit(current.copyWith(notes: updated));
  }

  Future<void> _onDelete(
      DeleteNoteRequested event, Emitter<NoteState> emit) async {
    await repository.deleteNote(event.id);
    await reminderService.cancel(event.id);
    if (state is! NoteLoaded) return;

    final current = state as NoteLoaded;
    emit(current.copyWith(
      notes: current.notes.where((n) => n.id != event.id).toList(),
    ));
  }

  Future<void> _onToggleItem(
      ToggleChecklistItemRequested event, Emitter<NoteState> emit) async {
    if (state is! NoteLoaded) return;
    final current = state as NoteLoaded;

    NoteEntity? changed;
    final updated = current.notes.map((note) {
      if (note.id != event.noteId) return note;
      changed = note.copyWith(
        items: note.items
            .map((i) => i.id == event.itemId ? i.copyWith(isDone: !i.isDone) : i)
            .toList(),
      );
      return changed!;
    }).toList();

    if (changed == null) return;
    emit(current.copyWith(notes: updated));
    await repository.saveNote(changed!);
    await reminderService.schedule(changed!);
  }

  Future<void> _onToggleDone(
      ToggleNoteDoneRequested event, Emitter<NoteState> emit) async {
    if (state is! NoteLoaded) return;
    final current = state as NoteLoaded;

    NoteEntity? changed;
    final updated = current.notes.map((note) {
      if (note.id != event.noteId) return note;
      changed = note.copyWith(isDone: !note.isDone);
      return changed!;
    }).toList();

    if (changed == null) return;
    emit(current.copyWith(notes: updated));
    await repository.saveNote(changed!);
    await reminderService.schedule(changed!);
  }
}
