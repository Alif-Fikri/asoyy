import 'package:equatable/equatable.dart';
import '../../domain/entities/bill_entity.dart';

abstract class SplitBillState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SplitBillInitial extends SplitBillState {}

class SplitBillLoading extends SplitBillState {}

class SplitBillLoaded extends SplitBillState {
  final List<BillEntity> bills;
  SplitBillLoaded(this.bills);

  SplitBillLoaded copyWith({List<BillEntity>? bills}) =>
      SplitBillLoaded(bills ?? this.bills);

  @override
  List<Object?> get props => [bills];
}

class SplitBillError extends SplitBillState {
  final String message;
  SplitBillError(this.message);
  @override
  List<Object?> get props => [message];
}
