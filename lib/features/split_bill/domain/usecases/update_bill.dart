import '../../../../core/usecase/usecase.dart';
import '../entities/bill_entity.dart';
import '../repositories/split_bill_repository.dart';

class UpdateBill implements UseCase<void, BillEntity> {
  final SplitBillRepository repository;
  UpdateBill(this.repository);

  @override
  Future<void> call(BillEntity params) => repository.updateBill(params);
}
