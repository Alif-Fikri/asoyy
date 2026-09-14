import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../domain/entities/debt_entity.dart';
import '../settlement_prompt.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';
import '../bloc/debt_state.dart';

class DebtDetailPage extends StatelessWidget {
  final String debtId;

  const DebtDetailPage({super.key, required this.debtId});

  Future<void> _toggleSettled(BuildContext context, DebtEntity debt) async {
    final settling = !debt.isSettled;
    context.read<DebtBloc>().add(
          UpdateDebtRequested(debt.copyWith(isSettled: settling)),
        );
    if (!settling || !context.mounted) return;
    await offerToRecordSettlement(context, debt);
  }

  void _confirmDelete(BuildContext context, String id) {
    final s = context.strings;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.confirm),
        content: Text(s.delete_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DebtBloc>().add(DeleteDebtRequested(id));
              Navigator.pop(context);
            },
            child: Text(s.delete, style: const TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return BlocBuilder<DebtBloc, DebtState>(
      builder: (context, state) {
        DebtEntity? debt;
        if (state is DebtLoaded) {
          for (final d in state.debts) {
            if (d.id == debtId) {
              debt = d;
              break;
            }
          }
        }

        if (debt == null) {
          return Scaffold(
            backgroundColor: c.background,
            appBar: NexusAppBar(title: s.debt_title),
            body: const SizedBox(),
          );
        }
        final d = debt;
        final isTheyOweMe = d.direction == DebtDirection.theyOweMe;
        final accent = isTheyOweMe ? AppColors.income : AppColors.expense;

        return Scaffold(
          backgroundColor: c.background,
          appBar: NexusAppBar(
            title: d.personName,
            extraActions: [
              IconButton(
                icon: const Icon(CupertinoIcons.trash),
                onPressed: () => _confirmDelete(context, d.id),
                tooltip: s.delete,
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                Insets.lg,
                Insets.lg,
                Insets.lg,
                MediaQuery.of(context).padding.bottom + Insets.xxl,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(Insets.lg),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (isTheyOweMe ? s.debt_owed_to_me : s.debt_i_owe).toUpperCase(),
                        style: AppType.label.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: Insets.sm),
                      Text(
                        fmt.format(d.amount),
                        style: AppType.display.copyWith(color: accent),
                      ),
                      const SizedBox(height: Insets.sm),
                      Text(
                        DateFormat('d MMM yyyy').format(d.date),
                        style: AppType.caption.copyWith(color: c.textSecondary),
                      ),
                      if (d.dueDate != null) ...[
                        const SizedBox(height: Insets.xs),
                        Text(
                          '${s.debt_due_date}: ${DateFormat('d MMM yyyy').format(d.dueDate!)}'
                          '${!d.isSettled && DateTime.now().isAfter(d.dueDate!) ? ' · ${s.debt_overdue}' : ''}',
                          style: AppType.caption.copyWith(
                            color: !d.isSettled && DateTime.now().isAfter(d.dueDate!)
                                ? AppColors.expense
                                : c.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (d.note != null) ...[
                        const SizedBox(height: Insets.sm),
                        Text(
                          d.note!,
                          style: AppType.body.copyWith(color: c.textPrimary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Insets.xl),
                Material(
                  color: c.card,
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.md),
                    onTap: () => _toggleSettled(context, d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.md,
                        vertical: Insets.sm,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            d.isSettled
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                            color: d.isSettled ? AppColors.income : c.textSecondary,
                            size: Sizes.iconLg,
                          ),
                          const SizedBox(width: Insets.md),
                          Text(
                            d.isSettled ? s.debt_settled : s.debt_mark_settled,
                            style: AppType.bodyStrong.copyWith(
                              color: d.isSettled ? AppColors.income : c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
