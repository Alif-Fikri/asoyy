import '../entities/transaction_entity.dart';

const int insightBaselineMonths = 3;

enum FinanceInsightType {
  spendingVsAverage,

  categoryTrend,

  budgetPace,

  budgetOver,

  topCategory,
}

enum InsightSentiment { good, neutral, warning }

class FinanceInsight {
  final FinanceInsightType type;
  final InsightSentiment sentiment;

  final String? category;

  final double ratio;

  final double amount;

  final int days;

  const FinanceInsight({
    required this.type,
    required this.sentiment,
    this.category,
    this.ratio = 0,
    this.amount = 0,
    this.days = 0,
  });
}

bool _isInMonth(TransactionEntity t, int year, int month) =>
    t.date.year == year && t.date.month == month;

double monthlyExpenseTotal(
  List<TransactionEntity> transactions,
  int year,
  int month,
) {
  var total = 0.0;
  for (final t in transactions) {
    if (!t.isExpense) continue;
    if (_isInMonth(t, year, month)) total += t.amount;
  }
  return total;
}

Map<String, double> monthlyExpenseByCategory(
  List<TransactionEntity> transactions,
  int year,
  int month,
) {
  final map = <String, double>{};
  for (final t in transactions) {
    if (!t.isExpense) continue;
    if (!_isInMonth(t, year, month)) continue;
    map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  return map;
}

List<({int year, int month})> _baselineMonths(DateTime now) => [
      for (var back = 1; back <= insightBaselineMonths; back++)
        (
          year: DateTime(now.year, now.month - back).year,
          month: DateTime(now.year, now.month - back).month,
        ),
    ];

double _baselineAverage(List<TransactionEntity> transactions, DateTime now) {
  var total = 0.0;
  var months = 0;
  for (final m in _baselineMonths(now)) {
    final value = monthlyExpenseTotal(transactions, m.year, m.month);
    if (value <= 0) continue;
    total += value;
    months++;
  }
  return months == 0 ? 0 : total / months;
}

Map<String, double> _baselineByCategory(
  List<TransactionEntity> transactions,
  DateTime now,
) {
  final totals = <String, double>{};
  var months = 0;
  for (final m in _baselineMonths(now)) {
    final byCategory = monthlyExpenseByCategory(transactions, m.year, m.month);
    if (byCategory.isEmpty) continue;
    months++;
    byCategory.forEach((k, v) => totals[k] = (totals[k] ?? 0) + v);
  }
  if (months == 0) return {};
  return totals.map((k, v) => MapEntry(k, v / months));
}

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

List<FinanceInsight> buildFinanceInsights({
  required List<TransactionEntity> transactions,
  required Map<String, double> budgets,
  required DateTime now,
  int maxInsights = 3,
}) {
  final thisMonth = monthlyExpenseTotal(transactions, now.year, now.month);
  final byCategory = monthlyExpenseByCategory(transactions, now.year, now.month);
  final insights = <FinanceInsight>[];

  final baseline = _baselineAverage(transactions, now);
  if (baseline > 0 && thisMonth > 0) {
    final change = (thisMonth - baseline) / baseline;
    if (change.abs() >= 0.10) {
      insights.add(FinanceInsight(
        type: FinanceInsightType.spendingVsAverage,
        sentiment:
            change > 0 ? InsightSentiment.warning : InsightSentiment.good,
        ratio: change,
        amount: (thisMonth - baseline).abs(),
      ));
    }
  }

  final categoryBaseline = _baselineByCategory(transactions, now);
  String? risingCategory;
  var risingRatio = 0.0;
  var risingAmount = 0.0;
  byCategory.forEach((category, spent) {
    final usual = categoryBaseline[category];
    if (usual == null || usual <= 0) return;
    final change = (spent - usual) / usual;
    if (change < 0.20) return;
    if (thisMonth > 0 && spent / thisMonth < 0.10) return;
    if (change > risingRatio) {
      risingCategory = category;
      risingRatio = change;
      risingAmount = spent - usual;
    }
  });
  if (risingCategory != null) {
    insights.add(FinanceInsight(
      type: FinanceInsightType.categoryTrend,
      sentiment: InsightSentiment.warning,
      category: risingCategory,
      ratio: risingRatio,
      amount: risingAmount,
    ));
  }

  var limitTotal = 0.0;
  var limitSpent = 0.0;
  budgets.forEach((category, limit) {
    if (limit <= 0) return;
    limitTotal += limit;
    limitSpent += byCategory[category] ?? 0;
  });
  if (limitTotal > 0) {
    final remaining = limitTotal - limitSpent;
    if (remaining <= 0) {
      insights.add(FinanceInsight(
        type: FinanceInsightType.budgetOver,
        sentiment: InsightSentiment.warning,
        ratio: limitSpent / limitTotal,
        amount: -remaining,
      ));
    } else {
      final daysElapsed = now.day;
      final dailyRate = limitSpent / daysElapsed;
      final daysLeft = daysInMonth(now.year, now.month) - now.day;
      if (dailyRate > 0) {
        final covered = (remaining / dailyRate).floor();
        insights.add(FinanceInsight(
          type: FinanceInsightType.budgetPace,
          sentiment: covered >= daysLeft
              ? InsightSentiment.good
              : InsightSentiment.warning,
          ratio: limitSpent / limitTotal,
          amount: remaining,
          days: covered,
        ));
      }
    }
  }

  if (insights.isEmpty && byCategory.isNotEmpty && thisMonth > 0) {
    final top =
        byCategory.entries.reduce((a, b) => a.value >= b.value ? a : b);
    insights.add(FinanceInsight(
      type: FinanceInsightType.topCategory,
      sentiment: InsightSentiment.neutral,
      category: top.key,
      ratio: top.value / thisMonth,
      amount: top.value,
    ));
  }

  insights.sort((a, b) {
    int rank(FinanceInsight i) =>
        i.sentiment == InsightSentiment.warning ? 0 : 1;
    return rank(a).compareTo(rank(b));
  });

  return insights.take(maxInsights).toList();
}
