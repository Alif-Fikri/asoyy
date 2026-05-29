import '../../../../core/usecase/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/finance_repository.dart';

class AddTransaction implements UseCase<void, TransactionEntity> {
  final FinanceRepository repository;
  AddTransaction(this.repository);

  @override
  Future<void> call(TransactionEntity params) => repository.addTransaction(params);
}
