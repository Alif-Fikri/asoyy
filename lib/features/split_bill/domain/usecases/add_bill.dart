import '../../../../core/usecase/usecase.dart';
import '../entities/bill_entity.dart';
import '../repositories/split_bill_repository.dart';

class AddBill implements UseCase<void, BillEntity> {
  final SplitBillRepository repository;
  AddBill(this.repository);

  @override
  Future<void> call(BillEntity params) => repository.addBill(params);
}
