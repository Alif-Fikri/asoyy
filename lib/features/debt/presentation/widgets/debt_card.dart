import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/debt_entity.dart';

class DebtCard extends StatelessWidget {
  final DebtEntity debt;
  final VoidCallback onTap;

  const DebtCard({super.key, required this.debt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isTheyOweMe = debt.direction == DebtDirection.theyOweMe;
    final accent = isTheyOweMe ? AppColors.income : AppColors.expense;

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Insets.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(
                  isTheyOweMe
                      ? CupertinoIcons.arrow_down_left
                      : CupertinoIcons.arrow_up_right,
                  color: accent,
                  size: Sizes.iconLg,
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        debt.personName,
                        style: AppType.bodyStrong.copyWith(color: c.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        debt.isSettled
                            ? s.debt_settled
                            : (isTheyOweMe ? s.debt_owed_to_me : s.debt_i_owe),
                        style: AppType.caption.copyWith(
                          color: debt.isSettled ? AppColors.income : c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  fmt.format(debt.amount),
                  style: AppType.bodyStrong.copyWith(
                    color: debt.isSettled ? c.textSecondary : accent,
                    decoration: debt.isSettled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
