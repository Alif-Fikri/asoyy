import 'package:asoyy/features/finance/domain/entities/recurring_transaction_entity.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/utils/recurring_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

RecurringTransactionEntity item({
  required int dayOfMonth,
  String? lastGeneratedMonth,
  bool isSubscription = false,
}) =>
    RecurringTransactionEntity(
      id: 'x',
      title: 'Netflix',
      amount: 54000,
      type: TransactionType.expense,
      category: 'Langganan',
      dayOfMonth: dayOfMonth,
      lastGeneratedMonth: lastGeneratedMonth,
      isSubscription: isSubscription,
    );

void main() {
  group('nextDueDate', () {
    test('due later this month stays in this month', () {
      final due = nextDueDate(item(dayOfMonth: 20), DateTime(2026, 3, 10));
      expect(due, DateTime(2026, 3, 20));
    });

    test('due today still counts as this month', () {
      final due = nextDueDate(item(dayOfMonth: 10), DateTime(2026, 3, 10, 18));
      expect(due, DateTime(2026, 3, 10));
    });

    test('already past this month rolls to next month', () {
      final due = nextDueDate(item(dayOfMonth: 5), DateTime(2026, 3, 10));
      expect(due, DateTime(2026, 4, 5));
    });

    test('already generated this month rolls to next month', () {
      final due = nextDueDate(
        item(dayOfMonth: 20, lastGeneratedMonth: '2026-03'),
        DateTime(2026, 3, 10),
      );
      expect(due, DateTime(2026, 4, 20));
    });

    test('generated in a previous month does not block this month', () {
      final due = nextDueDate(
        item(dayOfMonth: 20, lastGeneratedMonth: '2026-02'),
        DateTime(2026, 3, 10),
      );
      expect(due, DateTime(2026, 3, 20));
    });

    test('rolls over the year boundary', () {
      final due = nextDueDate(item(dayOfMonth: 5), DateTime(2026, 12, 10));
      expect(due, DateTime(2027, 1, 5));
    });

    test('day 31 in a 30-day month normalizes into the next month', () {
      final due = nextDueDate(item(dayOfMonth: 31), DateTime(2026, 4, 10));
      expect(due, DateTime(2026, 5, 1));
    });

    test('day 30 in February normalizes forward', () {
      final due = nextDueDate(item(dayOfMonth: 30), DateTime(2026, 2, 10));
      expect(due, DateTime(2026, 3, 2));
    });
  });

  group('nextReminderTime', () {
    test('a subscription is reminded 3 days ahead at 09:00', () {
      final t = nextReminderTime(
        item(dayOfMonth: 20, isSubscription: true),
        DateTime(2026, 3, 10),
      );
      expect(t, DateTime(2026, 3, 17, 9));
    });

    test('a plain recurring item is reminded 1 day ahead at 09:00', () {
      final t = nextReminderTime(
        item(dayOfMonth: 20),
        DateTime(2026, 3, 10),
      );
      expect(t, DateTime(2026, 3, 19, 9));
    });

    test('lead time can cross back into the previous month', () {
      final t = nextReminderTime(
        item(dayOfMonth: 2, isSubscription: true),
        DateTime(2026, 3, 10),
      );
      expect(t, DateTime(2026, 3, 30, 9));
    });
  });
}
