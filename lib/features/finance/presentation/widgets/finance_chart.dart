import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../domain/entities/transaction_entity.dart';

class FinanceChart extends StatelessWidget {
  final List<TransactionEntity> transactions;

  const FinanceChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    final now = DateTime.now();
    final months =
        List.generate(6, (i) => DateTime(now.year, now.month - 5 + i, 1));

    double maxVal = 0;
    final incomeData = <double>[];
    final expenseData = <double>[];

    for (final m in months) {
      final income = transactions
          .where(
            (t) =>
                t.isIncome && t.date.year == m.year && t.date.month == m.month,
          )
          .fold(0.0, (sum, t) => sum + t.amount);
      final expense = transactions
          .where(
            (t) =>
                !t.isIncome && t.date.year == m.year && t.date.month == m.month,
          )
          .fold(0.0, (sum, t) => sum + t.amount);
      incomeData.add(income);
      expenseData.add(expense);
      if (income > maxVal) maxVal = income;
      if (expense > maxVal) maxVal = expense;
    }

    if (maxVal == 0) maxVal = 1;

    final isId = context.currentLocale.languageCode == 'id';
    final labels = months
        .map((m) => DateFormat('MMM', isId ? 'id_ID' : 'en_US').format(m))
        .toList();

    final barGroups = List.generate(
      6,
      (i) => BarChartGroupData(
        x: i,
        barsSpace: 3,
        barRods: [
          BarChartRodData(
            toY: incomeData[i],
            color: AppColors.income,
            width: 8,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: expenseData[i],
            color: AppColors.expense,
            width: 8,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LegendDot(color: AppColors.income, label: s.fin_income),
              const SizedBox(width: 14),
              _LegendDot(color: AppColors.expense, label: s.fin_expense),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.25,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: c.divider, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => c.cardLight,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, _, rod, rodIndex) {
                      final fmt = NumberFormat.compact(locale: 'id_ID');
                      final label =
                          rodIndex == 0 ? s.fin_income : s.fin_expense;
                      return BarTooltipItem(
                        '$label\nRp ${fmt.format(rod.toY)}',
                        TextStyle(
                          color: rodIndex == 0
                              ? AppColors.income
                              : AppColors.expense,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
