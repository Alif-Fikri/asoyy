import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/bill_entity.dart';

class BillCard extends StatelessWidget {
  final BillEntity bill;
  final VoidCallback onTap;

  const BillCard({super.key, required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final paidCount = bill.participants.where((p) => p.isPaid).length;
    final total = bill.participants.length;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bill.title,
                        style: AppType.bodyStrong.copyWith(color: c.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (bill.isFullySettled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: Text(
                          s.splitbill_settled,
                          style: AppType.caption.copyWith(
                            color: AppColors.income,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  DateFormat('d MMM yyyy').format(bill.date),
                  style: AppType.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: Insets.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fmt.format(bill.totalAmount),
                      style: AppType.title.copyWith(color: c.textPrimary),
                    ),
                    Text(
                      '$paidCount/$total ${s.splitbill_paid}',
                      style: AppType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
