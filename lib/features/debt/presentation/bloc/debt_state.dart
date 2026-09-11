import 'package:equatable/equatable.dart';
import '../../domain/entities/debt_entity.dart';

abstract class DebtState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DebtInitial extends DebtState {}

class DebtLoading extends DebtState {}

class DebtLoaded extends DebtState {
  final List<DebtEntity> debts;
  DebtLoaded(this.debts);

  DebtLoaded copyWith({List<DebtEntity>? debts}) =>
      DebtLoaded(debts ?? this.debts);

  @override
  List<Object?> get props => [debts];
}

class DebtError extends DebtState {
  final String message;
  DebtError(this.message);
  @override
  List<Object?> get props => [message];
}
