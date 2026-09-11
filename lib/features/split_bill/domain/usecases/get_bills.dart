import '../../../../core/usecase/usecase.dart';
import '../entities/bill_entity.dart';
import '../repositories/split_bill_repository.dart';

class GetBills implements UseCase<List<BillEntity>, NoParams> {
  final SplitBillRepository repository;
  GetBills(this.repository);

  @override
  Future<List<BillEntity>> call(NoParams params) => repository.getBills();
}
