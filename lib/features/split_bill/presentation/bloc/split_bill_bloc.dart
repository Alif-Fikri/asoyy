import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/add_bill.dart';
import '../../domain/usecases/delete_bill.dart';
import '../../domain/usecases/get_bills.dart';
import '../../domain/usecases/update_bill.dart';
import 'split_bill_event.dart';
import 'split_bill_state.dart';

class SplitBillBloc extends Bloc<SplitBillBlocEvent, SplitBillState> {
  final GetBills getBills;
  final AddBill addBill;
  final UpdateBill updateBill;
  final DeleteBill deleteBill;

  SplitBillBloc({
    required this.getBills,
    required this.addBill,
    required this.updateBill,
    required this.deleteBill,
  }) : super(SplitBillInitial()) {
    on<LoadBills>(_onLoad);
    on<AddBillRequested>(_onAdd);
    on<UpdateBillRequested>(_onUpdate);
    on<DeleteBillRequested>(_onDelete);
  }

  Future<void> _onLoad(LoadBills event, Emitter<SplitBillState> emit) async {
    emit(SplitBillLoading());
    try {
      final bills = await getBills(const NoParams());
      bills.sort((a, b) => b.date.compareTo(a.date));
      emit(SplitBillLoaded(bills));
    } catch (e) {
      emit(SplitBillError(e.toString()));
    }
  }

  Future<void> _onAdd(AddBillRequested event, Emitter<SplitBillState> emit) async {
    if (state is! SplitBillLoaded) return;
    final current = state as SplitBillLoaded;
    await addBill(event.bill);
    emit(current.copyWith(bills: [event.bill, ...current.bills]));
  }

  Future<void> _onUpdate(UpdateBillRequested event, Emitter<SplitBillState> emit) async {
    if (state is! SplitBillLoaded) return;
    final current = state as SplitBillLoaded;
    await updateBill(event.bill);
    final updated = current.bills
        .map((b) => b.id == event.bill.id ? event.bill : b)
        .toList();
    emit(current.copyWith(bills: updated));
  }

  Future<void> _onDelete(DeleteBillRequested event, Emitter<SplitBillState> emit) async {
    if (state is! SplitBillLoaded) return;
    final current = state as SplitBillLoaded;
    await deleteBill(event.id);
    final updated = current.bills.where((b) => b.id != event.id).toList();
    emit(current.copyWith(bills: updated));
  }
}
