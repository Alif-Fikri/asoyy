import 'package:equatable/equatable.dart';
import '../../domain/entities/bill_entity.dart';

abstract class SplitBillBlocEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadBills extends SplitBillBlocEvent {}

class AddBillRequested extends SplitBillBlocEvent {
  final BillEntity bill;
  AddBillRequested(this.bill);
  @override
  List<Object?> get props => [bill.id];
}

class UpdateBillRequested extends SplitBillBlocEvent {
  final BillEntity bill;
  UpdateBillRequested(this.bill);
  @override
  List<Object?> get props => [bill.id];
}

class DeleteBillRequested extends SplitBillBlocEvent {
  final String id;
  DeleteBillRequested(this.id);
  @override
  List<Object?> get props => [id];
}
