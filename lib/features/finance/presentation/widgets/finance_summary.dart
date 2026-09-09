import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';

class FinanceSummary extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const FinanceSummary({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final s = context.strings;
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.fin_balance.toUpperCase(),
            style: AppType.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Insets.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              fmt.format(balance),
              style: AppType.display.copyWith(
                color: balance >= 0 ? c.textPrimary : AppColors.expense,
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: s.fin_income,
                  value: fmt.format(income),
                  color: AppColors.income,
                  icon: CupertinoIcons.arrow_down,
                ),
              ),
              Container(width: 0.5, height: Sizes.iconTile, color: c.divider),
              Expanded(
                child: _StatItem(
                  label: s.fin_expense,
                  value: fmt.format(expense),
                  color: AppColors.expense,
                  icon: CupertinoIcons.arrow_up,
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool alignEnd;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(
        left: alignEnd ? Insets.md : 0,
        right: alignEnd ? 0 : Insets.md,
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: Insets.xs),
              Text(
                label,
                style: AppType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          Text(
            value,
            style: AppType.bodyStrong.copyWith(color: c.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
