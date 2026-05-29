import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/transaction_model.dart';

abstract class FinanceLocalDatasource {
  Future<List<TransactionModel>> getTransactions();
  Future<void> addTransaction(TransactionModel tx);
  Future<void> deleteTransaction(String id);
}

class FinanceLocalDatasourceImpl implements FinanceLocalDatasource {
  final Box<TransactionModel> box;
  FinanceLocalDatasourceImpl(this.box);

  static Future<FinanceLocalDatasourceImpl> create() async {
    final box = await Hive.openBox<TransactionModel>(AppConstants.transactionsBox);
    return FinanceLocalDatasourceImpl(box);
  }

  @override
  Future<List<TransactionModel>> getTransactions() async => box.values.toList();

  @override
  Future<void> addTransaction(TransactionModel tx) => box.put(tx.id, tx);

  @override
  Future<void> deleteTransaction(String id) => box.delete(id);
}
