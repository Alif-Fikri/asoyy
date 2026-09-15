import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_local_datasource.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDatasource datasource;
  NoteRepositoryImpl(this.datasource);

  @override
  Future<List<NoteEntity>> getNotes() async {
    final models = await datasource.getNotes();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveNote(NoteEntity note) =>
      datasource.saveNote(NoteModel.fromEntity(note));

  @override
  Future<void> deleteNote(String id) => datasource.deleteNote(id);
}
