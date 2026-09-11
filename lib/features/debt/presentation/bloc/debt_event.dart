import 'package:equatable/equatable.dart';
import '../../domain/entities/debt_entity.dart';

abstract class DebtBlocEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDebts extends DebtBlocEvent {}

class AddDebtRequested extends DebtBlocEvent {
  final DebtEntity debt;
  AddDebtRequested(this.debt);
  @override
  List<Object?> get props => [debt.id];
}

class UpdateDebtRequested extends DebtBlocEvent {
  final DebtEntity debt;
  UpdateDebtRequested(this.debt);
  @override
  List<Object?> get props => [debt.id];
}

class DeleteDebtRequested extends DebtBlocEvent {
  final String id;
  DeleteDebtRequested(this.id);
  @override
  List<Object?> get props => [id];
}
