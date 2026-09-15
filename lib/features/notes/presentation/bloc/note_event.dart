import 'package:equatable/equatable.dart';
import '../../domain/entities/note_entity.dart';

abstract class NoteBlocEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotes extends NoteBlocEvent {}

class SaveNoteRequested extends NoteBlocEvent {
  final NoteEntity note;
  SaveNoteRequested(this.note);
  @override
  List<Object?> get props => [note.id];
}

class DeleteNoteRequested extends NoteBlocEvent {
  final String id;
  DeleteNoteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleChecklistItemRequested extends NoteBlocEvent {
  final String noteId;
  final String itemId;
  ToggleChecklistItemRequested({required this.noteId, required this.itemId});
  @override
  List<Object?> get props => [noteId, itemId];
}

class ToggleNoteDoneRequested extends NoteBlocEvent {
  final String noteId;
  ToggleNoteDoneRequested(this.noteId);
  @override
  List<Object?> get props => [noteId];
}
