import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/utils/finance_insights.dart';

/// Turns an insight into the sentence shown to the user.
String insightMessage(FinanceInsight insight, AppStrings s) {
  final money = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  String percent(double ratio) => '${(ratio.abs() * 100).round()}%';

  switch (insight.type) {
    case FinanceInsightType.spendingVsAverage:
      return insight.ratio > 0
          ? s.fin_insight_spending_up(percent(insight.ratio))
          : s.fin_insight_spending_down(percent(insight.ratio));
    case FinanceInsightType.categoryTrend:
      return s.fin_insight_category_up(
        insight.category ?? '',
        percent(insight.ratio),
      );
    case FinanceInsightType.budgetPace:
      return insight.sentiment == InsightSentiment.good
          ? s.fin_insight_budget_days(insight.days)
          : s.fin_insight_budget_today(money.format(insight.amount));
    case FinanceInsightType.budgetOver:
      return s.fin_insight_budget_over(money.format(insight.amount));
    case FinanceInsightType.topCategory:
      return s.fin_insight_top_category(
        insight.category ?? '',
        percent(insight.ratio),
      );
  }
}

IconData _iconFor(FinanceInsight insight) {
  switch (insight.type) {
    case FinanceInsightType.spendingVsAverage:
      return insight.ratio > 0
          ? CupertinoIcons.arrow_up_right
          : CupertinoIcons.arrow_down_right;
    case FinanceInsightType.categoryTrend:
      return CupertinoIcons.flame;
    case FinanceInsightType.budgetPace:
      return CupertinoIcons.gauge;
    case FinanceInsightType.budgetOver:
      return CupertinoIcons.exclamationmark_triangle;
    case FinanceInsightType.topCategory:
      return CupertinoIcons.chart_pie;
  }
}

Color _colorFor(InsightSentiment sentiment) {
  switch (sentiment) {
    case InsightSentiment.good:
      return AppColors.income;
    case InsightSentiment.warning:
      return AppColors.expense;
    case InsightSentiment.neutral:
      return AppColors.primary;
  }
}

class FinanceInsightsCard extends StatelessWidget {
  final List<FinanceInsight> insights;

  const FinanceInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;

    return Column(
      children: [
        for (var i = 0; i < insights.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(left: Insets.lg + Sizes.iconTile),
              child: Container(height: 0.5, color: c.divider),
            ),
          _InsightRow(
            insight: insights[i],
            message: insightMessage(insights[i], s),
          ),
        ],
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  final FinanceInsight insight;
  final String message;

  const _InsightRow({required this.insight, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _colorFor(insight.sentiment);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: Sizes.iconTile - Insets.sm,
            height: Sizes.iconTile - Insets.sm,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Icon(_iconFor(insight), size: Sizes.iconSm, color: color),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Text(
              message,
              style: AppType.caption.copyWith(color: c.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
