import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../../../core/usecase/usecase.dart';
import '../../services/finance_widget_service.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceBlocEvent, FinanceState> {
  final GetTransactions getTransactions;
  final AddTransaction addTransaction;
  final DeleteTransaction deleteTransaction;
  final FinanceWidgetService financeWidgetService;

  FinanceBloc({
    required this.getTransactions,
    required this.addTransaction,
    required this.deleteTransaction,
    required this.financeWidgetService,
  }) : super(FinanceInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransactionRequested>(_onAdd);
    on<DeleteTransactionRequested>(_onDelete);
    on<FilterChanged>(_onFilter);
    on<FilterPeriodChanged>(_onFilterPeriod);
  }

  Future<void> _onLoad(LoadTransactions event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    try {
      final txs = await getTransactions(const NoParams());
      txs.sort((a, b) => b.date.compareTo(a.date));
      final now = DateTime.now();
      emit(FinanceLoaded(all: txs, filterYear: now.year, filterMonth: now.month));
    } catch (e) {
      emit(FinanceError(e.toString()));
    }
  }

  Future<void> _onAdd(AddTransactionRequested event, Emitter<FinanceState> emit) async {
    if (state is! FinanceLoaded) return;
    final current = state as FinanceLoaded;
    await addTransaction(event.transaction);
    final updated = [event.transaction, ...current.all];
    emit(current.copyWith(all: updated));
    unawaited(financeWidgetService.updateWidget());
  }

  Future<void> _onDelete(DeleteTransactionRequested event, Emitter<FinanceState> emit) async {
    if (state is! FinanceLoaded) return;
    final current = state as FinanceLoaded;
    await deleteTransaction(event.id);
    emit(current.copyWith(all: current.all.where((t) => t.id != event.id).toList()));
    unawaited(financeWidgetService.updateWidget());
  }

  void _onFilter(FilterChanged event, Emitter<FinanceState> emit) {
    if (state is FinanceLoaded) {
      emit((state as FinanceLoaded).copyWith(filter: () => event.type));
    }
  }

  void _onFilterPeriod(FilterPeriodChanged event, Emitter<FinanceState> emit) {
    if (state is FinanceLoaded) {
      emit(
        (state as FinanceLoaded).copyWith(
          filterYear: () => event.year,
          filterMonth: () => event.month,
        ),
      );
    }
  }
}
