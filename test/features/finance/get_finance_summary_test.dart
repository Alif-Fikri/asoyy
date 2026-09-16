import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/usecases/get_finance_summary.dart';

TransactionEntity _tx({
  required TransactionType type,
  required double amount,
  required DateTime date,
}) =>
    TransactionEntity(
      id: 'id-${date.toIso8601String()}-$amount-${type.name}',
      title: 't',
      amount: amount,
      type: type,
      category: 'c',
      date: date,
    );

void main() {
  group('computeFinanceSummary', () {
    final now = DateTime(2026, 9, 16);

    test('balance nets income against expense and ignores transfers', () {
      final txs = [
        _tx(type: TransactionType.income, amount: 1000, date: now),
        _tx(type: TransactionType.expense, amount: 300, date: now),
        _tx(type: TransactionType.transfer, amount: 500, date: now),
      ];
      final summary = computeFinanceSummary(txs, now);
      expect(summary.totalBalance, 700);
    });

    test('todayExpense only counts expenses dated today', () {
      final txs = [
        _tx(type: TransactionType.expense, amount: 100, date: now),
        _tx(type: TransactionType.expense, amount: 200, date: now.subtract(const Duration(days: 1))),
        _tx(type: TransactionType.income, amount: 500, date: now),
      ];
      final summary = computeFinanceSummary(txs, now);
      expect(summary.todayExpense, 100);
    });

    test('monthIncome and monthExpense only count the current month', () {
      final txs = [
        _tx(type: TransactionType.income, amount: 5000000, date: DateTime(2026, 9, 1)),
        _tx(type: TransactionType.expense, amount: 300000, date: DateTime(2026, 9, 10)),
        _tx(type: TransactionType.expense, amount: 999999, date: DateTime(2026, 8, 20)),
        _tx(type: TransactionType.income, amount: 111111, date: DateTime(2026, 10, 1)),
      ];
      final summary = computeFinanceSummary(txs, now);
      expect(summary.monthIncome, 5000000);
      expect(summary.monthExpense, 300000);
    });

    test('an empty history yields all zeros', () {
      final summary = computeFinanceSummary(const [], now);
      expect(summary.totalBalance, 0);
      expect(summary.todayExpense, 0);
      expect(summary.monthIncome, 0);
      expect(summary.monthExpense, 0);
    });

    test('a transfer never affects month income or expense', () {
      final txs = [_tx(type: TransactionType.transfer, amount: 250000, date: now)];
      final summary = computeFinanceSummary(txs, now);
      expect(summary.monthIncome, 0);
      expect(summary.monthExpense, 0);
    });
  });
}
