import 'package:asoyy/features/debt/domain/entities/debt_entity.dart';
import 'package:asoyy/features/debt/domain/utils/bill_debt_link.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/split_bill/domain/entities/bill_entity.dart';
import 'package:flutter_test/flutter_test.dart';

ParticipantEntity person(String id, String name, double amount,
        {bool paid = false}) =>
    ParticipantEntity(id: id, name: name, amount: amount, isPaid: paid);

BillEntity bill(List<ParticipantEntity> participants) => BillEntity(
      id: 'bill1',
      title: 'Makan malam',
      totalAmount: participants.fold(0, (s, p) => s + p.amount),
      date: DateTime(2026, 9, 10),
      participants: participants,
      splitEqually: true,
    );

void main() {
  group('debtsFromBill', () {
    test('turns every unpaid participant into a receivable', () {
      final debts = debtsFromBill(
        bill([
          person('p1', 'Budi', 50000),
          person('p2', 'Sari', 50000),
        ]),
        const [],
        idFor: (p) => 'debt-${p.id}',
      );

      expect(debts, hasLength(2));
      expect(debts.map((d) => d.personName), ['Budi', 'Sari']);
      for (final debt in debts) {
        expect(debt.direction, DebtDirection.theyOweMe);
        expect(debt.amount, 50000);
        expect(debt.sourceBillId, 'bill1');
        expect(debt.isFromBill, isTrue);
        expect(debt.isSettled, isFalse);
      }
    });

    test('carries the bill name and date onto the debt', () {
      final debts = debtsFromBill(
        bill([person('p1', 'Budi', 50000)]),
        const [],
        idFor: (p) => 'd',
      );
      expect(debts.single.note, 'Makan malam');
      expect(debts.single.date, DateTime(2026, 9, 10));
    });

    test('skips participants who already paid', () {
      final debts = debtsFromBill(
        bill([
          person('p1', 'Budi', 50000, paid: true),
          person('p2', 'Sari', 50000),
        ]),
        const [],
        idFor: (p) => 'debt-${p.id}',
      );
      expect(debts.map((d) => d.personName), ['Sari']);
    });

    test('never creates a second debt for the same participant', () {
      final existing = debtsFromBill(
        bill([person('p1', 'Budi', 50000)]),
        const [],
        idFor: (p) => 'debt-${p.id}',
      );

      final again = debtsFromBill(
        bill([person('p1', 'Budi', 50000)]),
        existing,
        idFor: (p) => 'debt-lagi-${p.id}',
      );

      expect(again, isEmpty);
    });

    test('still skips a participant whose debt was already settled', () {
      final settled = [
        DebtEntity(
          id: 'd1',
          personName: 'Budi',
          amount: 50000,
          direction: DebtDirection.theyOweMe,
          date: DateTime(2026, 9, 10),
          isSettled: true,
          sourceBillId: 'bill1',
          sourceParticipantId: 'p1',
        ),
      ];

      final debts = debtsFromBill(
        bill([person('p1', 'Budi', 50000)]),
        settled,
        idFor: (p) => 'debt-${p.id}',
      );
      expect(debts, isEmpty);
    });

    test('ignores a participant with nothing to pay', () {
      final debts = debtsFromBill(
        bill([person('p1', 'Budi', 0), person('p2', 'Sari', 30000)]),
        const [],
        idFor: (p) => 'debt-${p.id}',
      );
      expect(debts.map((d) => d.personName), ['Sari']);
    });

    test('a debt from another bill does not block this one', () {
      final other = [
        DebtEntity(
          id: 'd1',
          personName: 'Budi',
          amount: 50000,
          direction: DebtDirection.theyOweMe,
          date: DateTime(2026, 9, 1),
          sourceBillId: 'bill-lain',
          sourceParticipantId: 'p1',
        ),
      ];
      final debts = debtsFromBill(
        bill([person('p1', 'Budi', 50000)]),
        other,
        idFor: (p) => 'debt-${p.id}',
      );
      expect(debts, hasLength(1));
    });
  });

  group('debtForParticipant', () {
    test('finds the debt belonging to a participant', () {
      final debts = debtsFromBill(
        bill([person('p1', 'Budi', 50000), person('p2', 'Sari', 50000)]),
        const [],
        idFor: (p) => 'debt-${p.id}',
      );
      expect(debtForParticipant(debts, 'bill1', 'p2')!.personName, 'Sari');
      expect(debtForParticipant(debts, 'bill1', 'p9'), isNull);
      expect(debtForParticipant(debts, 'bill9', 'p1'), isNull);
    });
  });

  group('transactionForSettledDebt', () {
    final theyOwe = DebtEntity(
      id: 'd1',
      personName: 'Budi',
      amount: 50000,
      direction: DebtDirection.theyOweMe,
      note: 'Makan malam',
      date: DateTime(2026, 9, 10),
    );

    test('money coming back is income', () {
      final tx = transactionForSettledDebt(
        theyOwe,
        id: 't1',
        settlementTitle: 'Pelunasan dari Budi',
        accountId: 'cash',
        on: DateTime(2026, 9, 14),
      );

      expect(tx.type, TransactionType.income);
      expect(tx.amount, 50000);
      expect(tx.title, 'Pelunasan dari Budi');
      expect(tx.accountId, 'cash');
      expect(tx.date, DateTime(2026, 9, 14));
      expect(tx.notes, 'Makan malam');
    });

    test('paying someone back is an expense', () {
      final tx = transactionForSettledDebt(
        theyOwe.copyWith(direction: DebtDirection.iOwe),
        id: 't2',
        settlementTitle: 'Bayar utang ke Budi',
        on: DateTime(2026, 9, 14),
      );
      expect(tx.type, TransactionType.expense);
      expect(tx.amount, 50000);
    });

    test('uses a category that exists for both directions', () {
      final income = transactionForSettledDebt(theyOwe,
          id: 't', settlementTitle: 'x', on: DateTime(2026, 9, 14));
      final expense = transactionForSettledDebt(
          theyOwe.copyWith(direction: DebtDirection.iOwe),
          id: 't',
          settlementTitle: 'x',
          on: DateTime(2026, 9, 14));

      expect(FinanceCategories.income, contains(income.category));
      expect(FinanceCategories.expense, contains(expense.category));
    });

    test('a settlement is never a transfer', () {
      for (final direction in DebtDirection.values) {
        final tx = transactionForSettledDebt(
          theyOwe.copyWith(direction: direction),
          id: 't',
          settlementTitle: 'x',
          on: DateTime(2026, 9, 14),
        );
        expect(tx.isTransfer, isFalse);
      }
    });
  });
}
