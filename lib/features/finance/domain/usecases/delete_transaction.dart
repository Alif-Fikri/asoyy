import '../../../../core/usecase/usecase.dart';
import '../repositories/finance_repository.dart';

class DeleteTransaction implements UseCase<void, String> {
  final FinanceRepository repository;
  DeleteTransaction(this.repository);

  @override
  Future<void> call(String params) => repository.deleteTransaction(params);
}
