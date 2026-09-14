import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/utils/finance_insights.dart';
import 'package:flutter_test/flutter_test.dart';

var _seq = 0;

TransactionEntity expense(double amount, DateTime date,
        {String category = 'Makan'}) =>
    TransactionEntity(
      id: 'e${_seq++}',
      title: category,
      amount: amount,
      type: TransactionType.expense,
      category: category,
      date: date,
    );

TransactionEntity income(double amount, DateTime date) => TransactionEntity(
      id: 'i${_seq++}',
      title: 'Gaji',
      amount: amount,
      type: TransactionType.income,
      category: 'Gaji',
      date: date,
    );

FinanceInsight? find(List<FinanceInsight> list, FinanceInsightType type) {
  for (final i in list) {
    if (i.type == type) return i;
  }
  return null;
}

void main() {
  // 15 June 2026: half the month elapsed, 30-day month.
  final now = DateTime(2026, 6, 15);

  group('monthlyExpenseTotal', () {
    test('sums only expenses in that month', () {
      final txs = [
        expense(100, DateTime(2026, 6, 1)),
        expense(200, DateTime(2026, 6, 20)),
        expense(999, DateTime(2026, 5, 20)),
        income(5000, DateTime(2026, 6, 5)),
      ];
      expect(monthlyExpenseTotal(txs, 2026, 6), 300);
    });

    test('is zero for a month with no data', () {
      expect(monthlyExpenseTotal([], 2026, 6), 0);
    });
  });

  group('monthlyExpenseByCategory', () {
    test('groups and ignores income', () {
      final txs = [
        expense(100, DateTime(2026, 6, 1), category: 'Makan'),
        expense(50, DateTime(2026, 6, 2), category: 'Makan'),
        expense(70, DateTime(2026, 6, 3), category: 'Transport'),
        income(5000, DateTime(2026, 6, 5)),
      ];
      expect(monthlyExpenseByCategory(txs, 2026, 6),
          {'Makan': 150.0, 'Transport': 70.0});
    });
  });

  group('daysInMonth', () {
    test('handles 30, 31 and February', () {
      expect(daysInMonth(2026, 6), 30);
      expect(daysInMonth(2026, 7), 31);
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2026, 12), 31);
    });
  });

  group('spending versus the 3-month average', () {
    List<TransactionEntity> baseline(double perMonth) => [
          expense(perMonth, DateTime(2026, 3, 10)),
          expense(perMonth, DateTime(2026, 4, 10)),
          expense(perMonth, DateTime(2026, 5, 10)),
        ];

    test('flags spending above the average', () {
      final insights = buildFinanceInsights(
        transactions: [...baseline(1000000), expense(1300000, DateTime(2026, 6, 5))],
        budgets: {},
        now: now,
      );
      final i = find(insights, FinanceInsightType.spendingVsAverage)!;
      expect(i.sentiment, InsightSentiment.warning);
      expect(i.ratio, closeTo(0.30, 0.0001));
      expect(i.amount, closeTo(300000, 0.01));
    });

    test('celebrates spending below the average', () {
      final insights = buildFinanceInsights(
        transactions: [...baseline(1000000), expense(700000, DateTime(2026, 6, 5))],
        budgets: {},
        now: now,
      );
      final i = find(insights, FinanceInsightType.spendingVsAverage)!;
      expect(i.sentiment, InsightSentiment.good);
      expect(i.ratio, closeTo(-0.30, 0.0001));
    });

    test('stays quiet for a change under 10%', () {
      final insights = buildFinanceInsights(
        transactions: [...baseline(1000000), expense(1050000, DateTime(2026, 6, 5))],
        budgets: {},
        now: now,
      );
      expect(find(insights, FinanceInsightType.spendingVsAverage), isNull);
    });

    test('only averages over months that actually had spending', () {
      // Only May has history, so the baseline is May alone, not May/3.
      final insights = buildFinanceInsights(
        transactions: [
          expense(1000000, DateTime(2026, 5, 10)),
          expense(1500000, DateTime(2026, 6, 5)),
        ],
        budgets: {},
        now: now,
      );
      final i = find(insights, FinanceInsightType.spendingVsAverage)!;
      expect(i.ratio, closeTo(0.50, 0.0001));
    });

    test('ignores months older than the baseline window', () {
      // February is 4 months back and must not count.
      final insights = buildFinanceInsights(
        transactions: [
          expense(9000000, DateTime(2026, 2, 10)),
          expense(1000000, DateTime(2026, 5, 10)),
          expense(1500000, DateTime(2026, 6, 5)),
        ],
        budgets: {},
        now: now,
      );
      expect(find(insights, FinanceInsightType.spendingVsAverage)!.ratio,
          closeTo(0.50, 0.0001));
    });

    test('income does not affect the comparison', () {
      final insights = buildFinanceInsights(
        transactions: [
          ...baseline(1000000),
          expense(1300000, DateTime(2026, 6, 5)),
          income(50000000, DateTime(2026, 6, 1)),
        ],
        budgets: {},
        now: now,
      );
      expect(find(insights, FinanceInsightType.spendingVsAverage)!.ratio,
          closeTo(0.30, 0.0001));
    });

    test('the baseline window reaches back across the year boundary', () {
      final jan = DateTime(2026, 1, 15);
      final insights = buildFinanceInsights(
        transactions: [
          expense(1000000, DateTime(2025, 12, 10)),
          expense(1500000, DateTime(2026, 1, 5)),
        ],
        budgets: {},
        now: jan,
      );
      expect(find(insights, FinanceInsightType.spendingVsAverage)!.ratio,
          closeTo(0.50, 0.0001));
    });
  });

  group('category trend', () {
    test('flags the category that grew the most', () {
      final txs = [
        for (final month in [3, 4, 5]) ...[
          expense(1000000, DateTime(2026, month, 10), category: 'Makan'),
          expense(1000000, DateTime(2026, month, 11), category: 'Transport'),
        ],
        expense(1100000, DateTime(2026, 6, 2), category: 'Makan'),
        expense(2000000, DateTime(2026, 6, 3), category: 'Transport'),
      ];
      final i = find(
        buildFinanceInsights(transactions: txs, budgets: {}, now: now),
        FinanceInsightType.categoryTrend,
      )!;
      expect(i.category, 'Transport');
      expect(i.ratio, closeTo(1.0, 0.0001));
      expect(i.amount, closeTo(1000000, 0.01));
    });

    test('ignores a rise under 20%', () {
      final txs = [
        for (final month in [3, 4, 5])
          expense(1000000, DateTime(2026, month, 10), category: 'Makan'),
        expense(1150000, DateTime(2026, 6, 2), category: 'Makan'),
      ];
      expect(
        find(
          buildFinanceInsights(transactions: txs, budgets: {}, now: now),
          FinanceInsightType.categoryTrend,
        ),
        isNull,
      );
    });

    test('ignores a category too small to matter this month', () {
      final txs = [
        for (final month in [3, 4, 5]) ...[
          expense(1000000, DateTime(2026, month, 10), category: 'Makan'),
          expense(1000, DateTime(2026, month, 11), category: 'Hiburan'),
        ],
        expense(1000000, DateTime(2026, 6, 2), category: 'Makan'),
        // tripled, but still under 10% of the month
        expense(3000, DateTime(2026, 6, 3), category: 'Hiburan'),
      ];
      expect(
        find(
          buildFinanceInsights(transactions: txs, budgets: {}, now: now),
          FinanceInsightType.categoryTrend,
        ),
        isNull,
      );
    });

    test('a brand new category has no baseline to compare against', () {
      final txs = [
        for (final month in [3, 4, 5])
          expense(1000000, DateTime(2026, month, 10), category: 'Makan'),
        expense(1000000, DateTime(2026, 6, 2), category: 'Makan'),
        expense(900000, DateTime(2026, 6, 3), category: 'Hiburan'),
      ];
      expect(
        find(
          buildFinanceInsights(transactions: txs, budgets: {}, now: now),
          FinanceInsightType.categoryTrend,
        ),
        isNull,
      );
    });
  });

  group('budget pace', () {
    test('remaining budget outlasts the month', () {
      // 1jt limit, 200rb spent by day 15 -> pace 13.3rb/day, 800rb left
      final i = find(
        buildFinanceInsights(
          transactions: [expense(200000, DateTime(2026, 6, 3))],
          budgets: {'Makan': 1000000},
          now: now,
        ),
        FinanceInsightType.budgetPace,
      )!;
      expect(i.sentiment, InsightSentiment.good);
      expect(i.amount, closeTo(800000, 0.01));
      expect(i.days, 60); // 800000 / (200000/15)
    });

    test('warns when the pace outruns the remaining days', () {
      // 1jt limit, 900rb spent by day 15 -> 100rb left, pace 60rb/day
      final i = find(
        buildFinanceInsights(
          transactions: [expense(900000, DateTime(2026, 6, 3))],
          budgets: {'Makan': 1000000},
          now: now,
        ),
        FinanceInsightType.budgetPace,
      )!;
      expect(i.sentiment, InsightSentiment.warning);
      expect(i.days, 1);
      expect(i.amount, closeTo(100000, 0.01));
    });

    test('reports how far over budget the month already is', () {
      final insights = buildFinanceInsights(
        transactions: [expense(1200000, DateTime(2026, 6, 3))],
        budgets: {'Makan': 1000000},
        now: now,
      );
      final i = find(insights, FinanceInsightType.budgetOver)!;
      expect(i.sentiment, InsightSentiment.warning);
      expect(i.amount, closeTo(200000, 0.01));
      // pace and over-budget are mutually exclusive
      expect(find(insights, FinanceInsightType.budgetPace), isNull);
    });

    test('only counts categories that actually have a limit', () {
      final i = find(
        buildFinanceInsights(
          transactions: [
            expense(200000, DateTime(2026, 6, 3), category: 'Makan'),
            expense(5000000, DateTime(2026, 6, 4), category: 'Belanja'),
          ],
          budgets: {'Makan': 1000000},
          now: now,
        ),
        FinanceInsightType.budgetPace,
      )!;
      expect(i.amount, closeTo(800000, 0.01));
    });

    test('a zero or negative limit is ignored', () {
      final insights = buildFinanceInsights(
        transactions: [expense(200000, DateTime(2026, 6, 3))],
        budgets: {'Makan': 0},
        now: now,
      );
      expect(find(insights, FinanceInsightType.budgetPace), isNull);
      expect(find(insights, FinanceInsightType.budgetOver), isNull);
    });

    test('no pace insight before anything has been spent', () {
      final insights = buildFinanceInsights(
        transactions: [],
        budgets: {'Makan': 1000000},
        now: now,
      );
      expect(find(insights, FinanceInsightType.budgetPace), isNull);
    });
  });

  group('fallback and ordering', () {
    test('shows the top category when nothing else applies', () {
      final insights = buildFinanceInsights(
        transactions: [
          expense(750000, DateTime(2026, 6, 2), category: 'Makan'),
          expense(250000, DateTime(2026, 6, 3), category: 'Transport'),
        ],
        budgets: {},
        now: now,
      );
      expect(insights, hasLength(1));
      expect(insights.single.type, FinanceInsightType.topCategory);
      expect(insights.single.category, 'Makan');
      expect(insights.single.ratio, closeTo(0.75, 0.0001));
    });

    test('returns nothing at all with no data', () {
      expect(
        buildFinanceInsights(transactions: [], budgets: {}, now: now),
        isEmpty,
      );
    });

    test('income-only months produce no insight', () {
      expect(
        buildFinanceInsights(
          transactions: [income(5000000, DateTime(2026, 6, 1))],
          budgets: {},
          now: now,
        ),
        isEmpty,
      );
    });

    test('warnings come first and the list is capped', () {
      final txs = [
        for (final month in [3, 4, 5])
          expense(1000000, DateTime(2026, month, 10), category: 'Makan'),
        // spending well below average (good) + a budget still on track (good)
        expense(200000, DateTime(2026, 6, 2), category: 'Makan'),
      ];
      final insights = buildFinanceInsights(
        transactions: txs,
        budgets: {'Makan': 1000000},
        now: now,
        maxInsights: 1,
      );
      expect(insights, hasLength(1));
    });

    test('a warning outranks a good insight', () {
      final txs = [
        for (final month in [3, 4, 5])
          expense(1000000, DateTime(2026, month, 10), category: 'Makan'),
        expense(500000, DateTime(2026, 6, 2), category: 'Makan'),
      ];
      // spending is down (good) but the budget is already blown (warning)
      final insights = buildFinanceInsights(
        transactions: txs,
        budgets: {'Makan': 400000},
        now: now,
      );
      expect(insights.first.sentiment, InsightSentiment.warning);
      expect(insights.first.type, FinanceInsightType.budgetOver);
    });
  });
}
