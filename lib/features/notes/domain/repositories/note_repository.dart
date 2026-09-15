import '../entities/note_entity.dart';

abstract class NoteRepository {
  Future<List<NoteEntity>> getNotes();
  Future<void> saveNote(NoteEntity note);
  Future<void> deleteNote(String id);
}
