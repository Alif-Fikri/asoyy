import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/note_model.dart';

abstract class NoteLocalDatasource {
  Future<List<NoteModel>> getNotes();
  Future<void> saveNote(NoteModel note);
  Future<void> deleteNote(String id);
}

class NoteLocalDatasourceImpl implements NoteLocalDatasource {
  final Box<NoteModel> box;
  NoteLocalDatasourceImpl(this.box);

  static Future<NoteLocalDatasourceImpl> create() async {
    final box = await Hive.openBox<NoteModel>(AppConstants.notesBox);
    return NoteLocalDatasourceImpl(box);
  }

  @override
  Future<List<NoteModel>> getNotes() async => box.values.toList();

  @override
  Future<void> saveNote(NoteModel note) => box.put(note.id, note);

  @override
  Future<void> deleteNote(String id) => box.delete(id);
}
