import '../entities/transaction_entity.dart';

abstract class FinanceRepository {
  Future<List<TransactionEntity>> getTransactions();
  Future<void> addTransaction(TransactionEntity tx);
  Future<void> deleteTransaction(String id);
}
