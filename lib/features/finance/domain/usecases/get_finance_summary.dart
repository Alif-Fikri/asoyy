import '../../../../core/usecase/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/finance_repository.dart';

class FinanceSummary {
  final double totalBalance;
  final double todayExpense;
  final double monthIncome;
  final double monthExpense;

  const FinanceSummary({
    required this.totalBalance,
    required this.todayExpense,
    required this.monthIncome,
    required this.monthExpense,
  });
}

FinanceSummary computeFinanceSummary(List<TransactionEntity> txs, DateTime now) {
  double balance = 0;
  double todayExpense = 0;
  double monthIncome = 0;
  double monthExpense = 0;

  for (final t in txs) {
    if (t.isTransfer) continue;
    balance += t.isIncome ? t.amount : -t.amount;

    final sameMonth = t.date.year == now.year && t.date.month == now.month;
    if (sameMonth) {
      if (t.isIncome) monthIncome += t.amount;
      if (t.isExpense) monthExpense += t.amount;
    }

    if (t.isExpense &&
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day) {
      todayExpense += t.amount;
    }
  }

  return FinanceSummary(
    totalBalance: balance,
    todayExpense: todayExpense,
    monthIncome: monthIncome,
    monthExpense: monthExpense,
  );
}

class GetFinanceSummary implements UseCase<FinanceSummary, NoParams> {
  final FinanceRepository repository;
  GetFinanceSummary(this.repository);

  @override
  Future<FinanceSummary> call(NoParams params) async {
    final txs = await repository.getTransactions();
    return computeFinanceSummary(txs, DateTime.now());
  }
}
