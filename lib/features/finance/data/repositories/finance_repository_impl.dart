import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_local_datasource.dart';
import '../models/transaction_model.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceLocalDatasource datasource;
  FinanceRepositoryImpl(this.datasource);

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final models = await datasource.getTransactions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addTransaction(TransactionEntity tx) =>
      datasource.addTransaction(TransactionModel.fromEntity(tx));

  @override
  Future<void> deleteTransaction(String id) => datasource.deleteTransaction(id);
}
