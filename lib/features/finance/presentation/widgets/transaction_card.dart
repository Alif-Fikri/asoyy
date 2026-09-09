import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionCard extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final dateFmt = DateFormat('d MMM', isId ? 'id_ID' : 'en_US');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () async {
          final confirmed = await showDeleteConfirm(context);
          if (confirmed) onDelete();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: Sizes.rowMinHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg,
            vertical: Insets.md,
          ),
          child: Row(
            children: [
              Container(
                width: Sizes.iconTile,
                height: Sizes.iconTile,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Radii.sm + 2),
                ),
                child: Icon(
                  isIncome
                      ? CupertinoIcons.arrow_down
                      : CupertinoIcons.arrow_up,
                  color: color,
                  size: Sizes.iconSm,
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.title,
                      style: AppType.body.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.category} · ${dateFmt.format(transaction.date)}',
                      style: AppType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.md),
              Text(
                '${isIncome ? '+' : '-'}${fmt.format(transaction.amount)}',
                style: AppType.bodyStrong.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
