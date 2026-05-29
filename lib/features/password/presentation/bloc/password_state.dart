import 'package:equatable/equatable.dart';
import '../../domain/entities/password_entity.dart';

abstract class PasswordState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PasswordInitial extends PasswordState {}

class PasswordLoading extends PasswordState {}

class PasswordLoaded extends PasswordState {
  final List<PasswordEntity> all;
  final String query;

  PasswordLoaded({required this.all, this.query = ''});

  List<PasswordEntity> get filtered {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.username.toLowerCase().contains(q) ||
            (p.website?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  PasswordLoaded copyWith({List<PasswordEntity>? all, String? query}) =>
      PasswordLoaded(all: all ?? this.all, query: query ?? this.query);

  @override
  List<Object?> get props => [all, query];
}

class PasswordError extends PasswordState {
  final String message;
  PasswordError(this.message);
  @override
  List<Object?> get props => [message];
}
