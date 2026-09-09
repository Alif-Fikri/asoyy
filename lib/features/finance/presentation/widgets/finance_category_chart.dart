import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';

const _palette = [
  Color(0xFFEF4444),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFF97316),
  Color(0xFF6366F1),
  Color(0xFF84CC16),
];

Color _colorFor(String category) {
  final hash = category.codeUnits.fold(0, (a, b) => a + b);
  return _palette[hash % _palette.length];
}

class FinanceCategoryChart extends StatefulWidget {
  final Map<String, double> expenseByCategory;

  const FinanceCategoryChart({super.key, required this.expenseByCategory});

  @override
  State<FinanceCategoryChart> createState() => _FinanceCategoryChartState();
}

class _FinanceCategoryChartState extends State<FinanceCategoryChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    final entries = widget.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            s.fin_category_chart_empty,
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final total = entries.fold(0.0, (sum, e) => sum + e.value);
    final fmt = NumberFormat.compact(locale: 'id_ID');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response?.touchedSection == null) {
                      setState(() => _touchedIndex = null);
                      return;
                    }
                    setState(() => _touchedIndex =
                        response!.touchedSection!.touchedSectionIndex);
                  },
                ),
                sections: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final isTouched = i == _touchedIndex;
                  final pct = total == 0 ? 0.0 : e.value / total * 100;
                  return PieChartSectionData(
                    value: e.value,
                    color: _colorFor(e.key),
                    radius: isTouched ? 26 : 22,
                    title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: entries.take(6).map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _colorFor(e.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Rp ${fmt.format(e.value)}',
                        style: TextStyle(color: c.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
