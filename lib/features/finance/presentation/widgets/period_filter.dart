import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';

class PeriodFilter extends StatelessWidget {
  final int? selectedYear;
  final int? selectedMonth;
  final void Function(int? year, int? month) onChanged;

  const PeriodFilter({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = [now.year, now.year - 1, now.year - 2];
    final isId = context.currentLocale.languageCode == 'id';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _yearRow(context, years),
        if (selectedYear != null) _monthRow(context, isId),
      ],
    );
  }

  Widget _yearRow(BuildContext context, List<int> years) {
    final s = context.strings;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _Chip(
            label: s.fin_all,
            isSelected: selectedYear == null,
            color: AppColors.primary,
            onTap: () => onChanged(null, null),
          ),
          ...years.map(
            (y) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _Chip(
                label: '$y',
                isSelected: selectedYear == y,
                color: AppColors.primary,
                onTap: () => onChanged(y, null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthRow(BuildContext context, bool isId) {
    final locale = isId ? 'id_ID' : 'en_US';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: List.generate(12, (i) {
          final month = i + 1;
          final label = DateFormat('MMM', locale).format(DateTime(2000, month));
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
            child: _Chip(
              label: label,
              isSelected: selectedMonth == month,
              color: AppColors.income,
              onTap: () => onChanged(
                selectedYear,
                selectedMonth == month ? null : month,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : c.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
