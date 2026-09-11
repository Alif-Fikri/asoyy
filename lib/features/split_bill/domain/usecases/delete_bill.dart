import '../../../../core/usecase/usecase.dart';
import '../repositories/split_bill_repository.dart';

class DeleteBill implements UseCase<void, String> {
  final SplitBillRepository repository;
  DeleteBill(this.repository);

  @override
  Future<void> call(String params) => repository.deleteBill(params);
}
