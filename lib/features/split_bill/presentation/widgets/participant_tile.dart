import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/bill_entity.dart';

class ParticipantTile extends StatelessWidget {
  final ParticipantEntity participant;
  final ValueChanged<bool> onTogglePaid;

  const ParticipantTile({
    super.key,
    required this.participant,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () => onTogglePaid(!participant.isPaid),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(
                  participant.isPaid
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  color: participant.isPaid ? AppColors.income : c.textSecondary,
                  size: Sizes.iconLg,
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        participant.name,
                        style: AppType.bodyStrong.copyWith(color: c.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        participant.isPaid ? s.splitbill_paid : s.splitbill_unpaid,
                        style: AppType.caption.copyWith(
                          color: participant.isPaid ? AppColors.income : c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  fmt.format(participant.amount),
                  style: AppType.bodyStrong.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
