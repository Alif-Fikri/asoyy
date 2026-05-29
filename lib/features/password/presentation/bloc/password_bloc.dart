import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/password_entity.dart';
import '../../domain/usecases/get_passwords.dart';
import '../../domain/usecases/save_password.dart';
import '../../domain/usecases/delete_password.dart';
import '../../../../core/usecase/usecase.dart';
import 'password_event.dart';
import 'password_state.dart';

class PasswordBloc extends Bloc<PasswordBlocEvent, PasswordState> {
  final GetPasswords getPasswords;
  final SavePassword savePassword;
  final DeletePassword deletePassword;

  PasswordBloc({
    required this.getPasswords,
    required this.savePassword,
    required this.deletePassword,
  }) : super(PasswordInitial()) {
    on<LoadPasswords>(_onLoad);
    on<SavePasswordRequested>(_onSave);
    on<DeletePasswordRequested>(_onDelete);
    on<SearchPasswords>(_onSearch);
  }

  Future<void> _onLoad(LoadPasswords event, Emitter<PasswordState> emit) async {
    emit(PasswordLoading());
    try {
      final list = await getPasswords(const NoParams());
      emit(PasswordLoaded(all: list));
    } catch (e) {
      emit(PasswordError(e.toString()));
    }
  }

  Future<void> _onSave(SavePasswordRequested event, Emitter<PasswordState> emit) async {
    if (state is! PasswordLoaded) return;
    final current = state as PasswordLoaded;
    await savePassword(event.password);
    final idx = current.all.indexWhere((p) => p.id == event.password.id);
    List<PasswordEntity> updated;
    if (idx >= 0) {
      updated = [...current.all]..[idx] = event.password;
    } else {
      updated = [...current.all, event.password];
    }
    emit(current.copyWith(all: updated));
  }

  Future<void> _onDelete(DeletePasswordRequested event, Emitter<PasswordState> emit) async {
    if (state is! PasswordLoaded) return;
    final current = state as PasswordLoaded;
    await deletePassword(event.id);
    emit(current.copyWith(all: current.all.where((p) => p.id != event.id).toList()));
  }

  void _onSearch(SearchPasswords event, Emitter<PasswordState> emit) {
    if (state is PasswordLoaded) {
      emit((state as PasswordLoaded).copyWith(query: event.query));
    }
  }
}
