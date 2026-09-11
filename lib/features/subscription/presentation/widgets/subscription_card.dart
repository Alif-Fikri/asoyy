import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../finance/domain/entities/recurring_transaction_entity.dart';
import '../../../finance/domain/utils/recurring_schedule.dart';

class SubscriptionCard extends StatelessWidget {
  final RecurringTransactionEntity subscription;
  final VoidCallback onDelete;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final nextRenewal = nextDueDate(subscription, DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: Container(
        padding: const EdgeInsets.all(Insets.lg),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.subscriptionColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: const Icon(
                CupertinoIcons.arrow_2_circlepath,
                color: AppColors.subscriptionColor,
                size: Sizes.iconLg,
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subscription.title,
                    style: AppType.bodyStrong.copyWith(color: c.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.subscription_next_renewal}: ${DateFormat('d MMM yyyy').format(nextRenewal)}',
                    style: AppType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(subscription.amount),
                  style: AppType.bodyStrong.copyWith(color: c.textPrimary),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.trash, color: c.textSecondary, size: 18),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
