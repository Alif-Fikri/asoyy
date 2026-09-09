import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';

Future<int?> showRecurringDayPicker(BuildContext context, int selected) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RecurringDayPickerSheet(selected: selected),
  );
}

class RecurringDayPickerSheet extends StatelessWidget {
  final int selected;

  const RecurringDayPickerSheet({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.fin_recurring_day_label,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(28, (i) {
              final day = i + 1;
              final isSelected = day == selected;
              return GestureDetector(
                onTap: () => Navigator.pop(context, day),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : c.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : c.border,
                    ),
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected ? Colors.white : c.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
