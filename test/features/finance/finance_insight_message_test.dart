import 'package:asoyy/core/l10n/strings_en.dart';
import 'package:asoyy/core/l10n/strings_id.dart';
import 'package:asoyy/features/finance/domain/utils/finance_insights.dart';
import 'package:asoyy/features/finance/presentation/widgets/finance_insights_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final id = StringsId();
  final en = StringsEn();

  test('every insight type renders a non-empty sentence in both locales', () {
    final samples = [
      const FinanceInsight(
        type: FinanceInsightType.spendingVsAverage,
        sentiment: InsightSentiment.warning,
        ratio: 0.23,
        amount: 230000,
      ),
      const FinanceInsight(
        type: FinanceInsightType.spendingVsAverage,
        sentiment: InsightSentiment.good,
        ratio: -0.23,
        amount: 230000,
      ),
      const FinanceInsight(
        type: FinanceInsightType.categoryTrend,
        sentiment: InsightSentiment.warning,
        category: 'Makan',
        ratio: 0.5,
      ),
      const FinanceInsight(
        type: FinanceInsightType.budgetPace,
        sentiment: InsightSentiment.good,
        days: 9,
      ),
      const FinanceInsight(
        type: FinanceInsightType.budgetPace,
        sentiment: InsightSentiment.warning,
        amount: 100000,
      ),
      const FinanceInsight(
        type: FinanceInsightType.budgetOver,
        sentiment: InsightSentiment.warning,
        amount: 200000,
      ),
      const FinanceInsight(
        type: FinanceInsightType.topCategory,
        sentiment: InsightSentiment.neutral,
        category: 'Transport',
        ratio: 0.4,
      ),
    ];

    for (final insight in samples) {
      for (final strings in [id, en]) {
        final message = insightMessage(insight, strings);
        expect(message.trim(), isNotEmpty, reason: '${insight.type}');
        expect(message, isNot(contains('null')), reason: '${insight.type}');
      }
    }
  });

  test('percentages are rendered without a sign or decimals', () {
    final up = insightMessage(
      const FinanceInsight(
        type: FinanceInsightType.spendingVsAverage,
        sentiment: InsightSentiment.warning,
        ratio: 0.234,
      ),
      id,
    );
    expect(up, contains('23%'));

    final down = insightMessage(
      const FinanceInsight(
        type: FinanceInsightType.spendingVsAverage,
        sentiment: InsightSentiment.good,
        ratio: -0.234,
      ),
      id,
    );
    expect(down, contains('23%'));
    expect(down, isNot(contains('-23%')));
  });

  test('amounts are formatted as rupiah', () {
    final message = insightMessage(
      const FinanceInsight(
        type: FinanceInsightType.budgetOver,
        sentiment: InsightSentiment.warning,
        amount: 200000,
      ),
      id,
    );
    expect(message, contains('Rp'));
    expect(message, contains('200.000'));
  });
}
