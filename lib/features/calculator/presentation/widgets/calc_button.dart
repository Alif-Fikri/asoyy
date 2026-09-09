import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_color_theme.dart';

enum CalcButtonStyle { number, operator, action, equals }

class CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final CalcButtonStyle style;
  final int flex;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.style = CalcButtonStyle.number,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final Color bgColor;
    switch (style) {
      case CalcButtonStyle.operator:
        bgColor = AppColors.calculatorColor.withValues(alpha: 0.15);
      case CalcButtonStyle.action:
        bgColor = c.cardLight;
      case CalcButtonStyle.equals:
        bgColor = AppColors.calculatorColor;
      case CalcButtonStyle.number:
        bgColor = c.card;
    }

    final Color fgColor;
    switch (style) {
      case CalcButtonStyle.operator:
        fgColor = AppColors.calculatorColor;
      case CalcButtonStyle.action:
        fgColor = c.textSecondary;
      case CalcButtonStyle.equals:
        fgColor = Colors.white;
      case CalcButtonStyle.number:
        fgColor = c.textPrimary;
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: style == CalcButtonStyle.equals
                ? null
                : Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: bgColor,
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 70,
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: label.length > 1 ? 18 : 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
