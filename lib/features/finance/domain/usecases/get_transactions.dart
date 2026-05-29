import '../../../../core/usecase/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/finance_repository.dart';

class GetTransactions implements UseCase<List<TransactionEntity>, NoParams> {
  final FinanceRepository repository;
  GetTransactions(this.repository);

  @override
  Future<List<TransactionEntity>> call(NoParams params) => repository.getTransactions();
}
