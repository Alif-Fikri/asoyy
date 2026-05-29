import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class FinanceBlocEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends FinanceBlocEvent {}

class AddTransactionRequested extends FinanceBlocEvent {
  final TransactionEntity transaction;
  AddTransactionRequested(this.transaction);
  @override
  List<Object?> get props => [transaction.id];
}

class DeleteTransactionRequested extends FinanceBlocEvent {
  final String id;
  DeleteTransactionRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class FilterChanged extends FinanceBlocEvent {
  final TransactionType? type;
  FilterChanged(this.type);
  @override
  List<Object?> get props => [type];
}

class FilterPeriodChanged extends FinanceBlocEvent {
  final int? year;
  final int? month;
  FilterPeriodChanged({this.year, this.month});
  @override
  List<Object?> get props => [year, month];
}
