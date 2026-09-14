import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/add_debt.dart';
import '../../domain/usecases/delete_debt.dart';
import '../../domain/usecases/get_debts.dart';
import '../../domain/usecases/update_debt.dart';
import '../../services/debt_reminder_service.dart';
import 'debt_event.dart';
import 'debt_state.dart';

class DebtBloc extends Bloc<DebtBlocEvent, DebtState> {
  final GetDebts getDebts;
  final AddDebt addDebt;
  final UpdateDebt updateDebt;
  final DeleteDebt deleteDebt;
  final DebtReminderService reminderService;

  DebtBloc({
    required this.getDebts,
    required this.addDebt,
    required this.updateDebt,
    required this.deleteDebt,
    required this.reminderService,
  }) : super(DebtInitial()) {
    on<LoadDebts>(_onLoad);
    on<AddDebtRequested>(_onAdd);
    on<AddDebtsRequested>(_onAddMany);
    on<UpdateDebtRequested>(_onUpdate);
    on<DeleteDebtRequested>(_onDelete);
  }

  Future<void> _onLoad(LoadDebts event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    try {
      final debts = await getDebts(const NoParams());
      debts.sort((a, b) => b.date.compareTo(a.date));
      emit(DebtLoaded(debts));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }

  Future<void> _onAdd(AddDebtRequested event, Emitter<DebtState> emit) async {
    if (state is! DebtLoaded) return;
    final current = state as DebtLoaded;
    await addDebt(event.debt);
    emit(current.copyWith(debts: [event.debt, ...current.debts]));
    await reminderService.rescheduleAll();
  }

  Future<void> _onAddMany(
      AddDebtsRequested event, Emitter<DebtState> emit) async {
    if (state is! DebtLoaded) return;
    if (event.debts.isEmpty) return;
    final current = state as DebtLoaded;
    for (final debt in event.debts) {
      await addDebt(debt);
    }
    emit(current.copyWith(debts: [...event.debts.reversed, ...current.debts]));
    await reminderService.rescheduleAll();
  }

  Future<void> _onUpdate(UpdateDebtRequested event, Emitter<DebtState> emit) async {
    if (state is! DebtLoaded) return;
    final current = state as DebtLoaded;
    await updateDebt(event.debt);
    final updated =
        current.debts.map((d) => d.id == event.debt.id ? event.debt : d).toList();
    emit(current.copyWith(debts: updated));
    await reminderService.rescheduleAll();
  }

  Future<void> _onDelete(DeleteDebtRequested event, Emitter<DebtState> emit) async {
    if (state is! DebtLoaded) return;
    final current = state as DebtLoaded;
    await deleteDebt(event.id);
    final updated = current.debts.where((d) => d.id != event.id).toList();
    emit(current.copyWith(debts: updated));
    await reminderService.cancelReminder('debt-${event.id}');
  }
}
