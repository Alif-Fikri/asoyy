import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class FinanceState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final List<TransactionEntity> all;
  final TransactionType? filter;
  final int? filterYear;
  final int? filterMonth;

  FinanceLoaded({
    required this.all,
    this.filter,
    this.filterYear,
    this.filterMonth,
  });

  List<TransactionEntity> get _periodFiltered {
    if (filterYear == null) return all;
    return all.where((t) {
      if (t.date.year != filterYear) return false;
      if (filterMonth != null && t.date.month != filterMonth) return false;
      return true;
    }).toList();
  }

  List<TransactionEntity> get filtered {
    if (filter == null) return _periodFiltered;
    return _periodFiltered.where((t) => t.type == filter).toList();
  }

  double get totalIncome =>
      _periodFiltered.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);

  double get totalExpense =>
      _periodFiltered.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount);

  double get balance => totalIncome - totalExpense;

  Map<String, double> get expenseByCategory {
    final map = <String, double>{};
    for (final t in _periodFiltered.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  FinanceLoaded copyWith({
    List<TransactionEntity>? all,
    TransactionType? Function()? filter,
    int? Function()? filterYear,
    int? Function()? filterMonth,
  }) =>
      FinanceLoaded(
        all: all ?? this.all,
        filter: filter != null ? filter() : this.filter,
        filterYear: filterYear != null ? filterYear() : this.filterYear,
        filterMonth: filterMonth != null ? filterMonth() : this.filterMonth,
      );

  @override
  List<Object?> get props => [all, filter, filterYear, filterMonth];
}

class FinanceError extends FinanceState {
  final String message;
  FinanceError(this.message);
  @override
  List<Object?> get props => [message];
}
