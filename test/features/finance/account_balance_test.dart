import 'package:asoyy/features/finance/domain/entities/account_entity.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/utils/account_balance.dart';
import 'package:flutter_test/flutter_test.dart';

var _seq = 0;

AccountEntity account(String id, {double initial = 0}) => AccountEntity(
      id: id,
      name: id,
      type: AccountType.cash,
      initialBalance: initial,
    );

TransactionEntity tx(
  TransactionType type,
  double amount, {
  String? from,
  String? to,
}) =>
    TransactionEntity(
      id: 't${_seq++}',
      title: 'x',
      amount: amount,
      type: type,
      category: type == TransactionType.transfer ? transferCategory : 'Makan',
      date: DateTime(2026, 6, 1),
      accountId: from,
      toAccountId: to,
    );

void main() {
  final cash = account('cash', initial: 500000);
  final bank = account('bank', initial: 2000000);

  group('accountBalance', () {
    test('starts at the opening balance', () {
      expect(accountBalance(cash, []), 500000);
    });

    test('income adds and expense subtracts', () {
      final txs = [
        tx(TransactionType.income, 300000, from: 'cash'),
        tx(TransactionType.expense, 100000, from: 'cash'),
      ];
      expect(accountBalance(cash, txs), 700000);
    });

    test('ignores movement on other accounts', () {
      final txs = [
        tx(TransactionType.income, 300000, from: 'bank'),
        tx(TransactionType.expense, 100000, from: 'bank'),
      ];
      expect(accountBalance(cash, txs), 500000);
    });

    test('a transfer leaves the source and lands in the target', () {
      final txs = [tx(TransactionType.transfer, 200000, from: 'bank', to: 'cash')];
      expect(accountBalance(bank, txs), 1800000);
      expect(accountBalance(cash, txs), 700000);
    });

    test('a transaction with no account does not move any balance', () {
      final txs = [tx(TransactionType.expense, 100000)];
      expect(accountBalance(cash, txs), 500000);
      expect(accountBalance(bank, txs), 2000000);
    });

    test('can go negative', () {
      final txs = [tx(TransactionType.expense, 900000, from: 'cash')];
      expect(accountBalance(cash, txs), -400000);
    });
  });

  group('totalBalance', () {
    test('sums every account', () {
      expect(totalBalance([cash, bank], []), 2500000);
    });

    test('a transfer does not change the total', () {
      final txs = [tx(TransactionType.transfer, 200000, from: 'bank', to: 'cash')];
      expect(totalBalance([cash, bank], txs), 2500000);
    });

    test('a top-up is not spending', () {
      final txs = [tx(TransactionType.transfer, 100000, from: 'bank', to: 'cash')];
      final spent = txs.where((t) => t.isExpense).fold<double>(0, (s, t) => s + t.amount);
      expect(spent, 0);
      expect(totalBalance([cash, bank], txs), 2500000);
    });

    test('income and expense move the total', () {
      final txs = [
        tx(TransactionType.income, 1000000, from: 'bank'),
        tx(TransactionType.expense, 250000, from: 'cash'),
      ];
      expect(totalBalance([cash, bank], txs), 3250000);
    });

    test('money on an unknown account is still counted, never lost', () {
      final txs = [
        tx(TransactionType.income, 400000, from: 'hilang'),
        tx(TransactionType.expense, 150000),
      ];
      expect(totalBalance([cash, bank], txs), 2500000 + 400000 - 150000);
    });

    test('a transfer to a deleted account is not double counted', () {
      final txs = [tx(TransactionType.transfer, 200000, from: 'cash', to: 'hilang')];
      expect(totalBalance([cash, bank], txs), 2300000);
    });

    test('with no accounts at all it falls back to the plain net', () {
      final txs = [
        tx(TransactionType.income, 1000000),
        tx(TransactionType.expense, 300000),
      ];
      expect(totalBalance([], txs), 700000);
    });
  });

  group('balanceByAccount', () {
    test('reports each account separately', () {
      final txs = [
        tx(TransactionType.expense, 100000, from: 'cash'),
        tx(TransactionType.transfer, 500000, from: 'bank', to: 'cash'),
      ];
      expect(balanceByAccount([cash, bank], txs), {
        'cash': 900000.0,
        'bank': 1500000.0,
      });
    });

    test('is empty when there are no accounts', () {
      expect(balanceByAccount([], []), isEmpty);
    });
  });
}
