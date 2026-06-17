import 'package:equatable/equatable.dart';
import '../../domain/entities/password_entity.dart';

abstract class PasswordBlocEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPasswords extends PasswordBlocEvent {}

class SavePasswordRequested extends PasswordBlocEvent {
  final PasswordEntity password;
  SavePasswordRequested(this.password);
  @override
  List<Object?> get props => [password.id];
}

class DeletePasswordRequested extends PasswordBlocEvent {
  final String id;
  DeletePasswordRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class SearchPasswords extends PasswordBlocEvent {
  final String query;
  SearchPasswords(this.query);
  @override
  List<Object?> get props => [query];
}

class ImportPasswordsRequested extends PasswordBlocEvent {
  final List<PasswordEntity> passwords;
  ImportPasswordsRequested(this.passwords);
  @override
  List<Object?> get props => [passwords.length];
}
