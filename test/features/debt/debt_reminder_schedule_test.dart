import 'package:asoyy/features/debt/domain/utils/debt_reminder_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextDebtReminderTime', () {
    test('first reminder is one interval after the start', () {
      final next = nextDebtReminderTime(
        DateTime(2026, 3, 1, 9),
        DateTime(2026, 3, 1, 12),
      );
      expect(next, DateTime(2026, 3, 4, 9));
    });

    test('skips past intervals that have already elapsed', () {
      final next = nextDebtReminderTime(
        DateTime(2026, 3, 1, 9),
        DateTime(2026, 3, 10, 12),
      );
      expect(next, DateTime(2026, 3, 13, 9));
    });

    test('a reminder due exactly now moves to the following interval', () {
      final next = nextDebtReminderTime(
        DateTime(2026, 3, 1, 9),
        DateTime(2026, 3, 4, 9),
      );
      expect(next, DateTime(2026, 3, 7, 9));
    });

    test('always returns a time strictly in the future', () {
      final now = DateTime(2026, 6, 15, 20, 30);
      for (final daysAgo in [0, 1, 3, 4, 29, 100, 365]) {
        final next =
            nextDebtReminderTime(now.subtract(Duration(days: daysAgo)), now);
        expect(next.isAfter(now), isTrue, reason: '$daysAgo hari lalu');
        expect(
          next.difference(now).inDays,
          lessThanOrEqualTo(debtReminderIntervalDays),
          reason: 'tidak melompati interval',
        );
      }
    });
  });

  group('daysSince', () {
    test('counts whole elapsed days', () {
      expect(daysSince(DateTime(2026, 3, 1, 9), DateTime(2026, 3, 10, 9)), 9);
    });

    test('a partial day does not count', () {
      expect(daysSince(DateTime(2026, 3, 1, 9), DateTime(2026, 3, 2, 8)), 0);
    });

    test('is zero at the moment the debt starts', () {
      final t = DateTime(2026, 3, 1, 9);
      expect(daysSince(t, t), 0);
    });
  });
}
