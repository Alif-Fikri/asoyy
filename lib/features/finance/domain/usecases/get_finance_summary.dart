import '../../../../core/usecase/usecase.dart';
import '../repositories/finance_repository.dart';

class FinanceSummary {
  final double totalBalance;
  final double todayExpense;

  const FinanceSummary({required this.totalBalance, required this.todayExpense});
}

class GetFinanceSummary implements UseCase<FinanceSummary, NoParams> {
  final FinanceRepository repository;
  GetFinanceSummary(this.repository);

  @override
  Future<FinanceSummary> call(NoParams params) async {
    final txs = await repository.getTransactions();
    final now = DateTime.now();

    double balance = 0;
    double todayExpense = 0;
    for (final t in txs) {
      if (t.isTransfer) continue;
      balance += t.isIncome ? t.amount : -t.amount;
      if (t.isExpense &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day) {
        todayExpense += t.amount;
      }
    }
    return FinanceSummary(totalBalance: balance, todayExpense: todayExpense);
  }
}
