import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../debt/domain/entities/debt_entity.dart';
import '../../../debt/domain/utils/bill_debt_link.dart';
import '../../../debt/presentation/bloc/debt_bloc.dart';
import '../../../debt/presentation/bloc/debt_event.dart';
import '../../../debt/presentation/bloc/debt_state.dart';
import '../../../debt/presentation/settlement_prompt.dart';
import '../../domain/entities/bill_entity.dart';
import '../bloc/split_bill_bloc.dart';
import '../bloc/split_bill_event.dart';
import '../bloc/split_bill_state.dart';
import '../widgets/participant_tile.dart';

class SplitBillDetailPage extends StatelessWidget {
  final String billId;

  const SplitBillDetailPage({super.key, required this.billId});

  List<DebtEntity> _debts(BuildContext context) {
    final state = context.read<DebtBloc>().state;
    return state is DebtLoaded ? state.debts : const [];
  }

  Future<void> _togglePaid(BuildContext context, BillEntity bill,
      String participantId, bool isPaid) async {
    final updatedParticipants = bill.participants
        .map((p) => p.id == participantId ? p.copyWith(isPaid: isPaid) : p)
        .toList();
    context.read<SplitBillBloc>().add(
          UpdateBillRequested(bill.copyWith(participants: updatedParticipants)),
        );
    if (!isPaid) return;

    final linked = debtForParticipant(_debts(context), bill.id, participantId);
    if (linked == null || linked.isSettled || !context.mounted) return;

    context
        .read<DebtBloc>()
        .add(UpdateDebtRequested(linked.copyWith(isSettled: true)));
    if (!context.mounted) return;
    await offerToRecordSettlement(context, linked);
  }

  Future<void> _makeReceivables(BuildContext context, BillEntity bill) async {
    final s = context.strings;
    final created = debtsFromBill(
      bill,
      _debts(context),
      idFor: (_) => const Uuid().v4(),
    );

    if (created.isEmpty) {
      AppToast.show(context, s.link_receivable_none);
      return;
    }

    context.read<DebtBloc>().add(AddDebtsRequested(created));
    AppToast.show(context, s.link_receivable_created(created.length));
  }

  void _share(BuildContext context, BillEntity bill) {
    final s = context.strings;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final buffer = StringBuffer()
      ..writeln(bill.title)
      ..writeln('${s.splitbill_total_amount.replaceAll(' (Rp)', '')}: ${fmt.format(bill.totalAmount)}')
      ..writeln();
    for (final p in bill.participants) {
      final status = p.isPaid ? s.splitbill_paid : s.splitbill_unpaid;
      buffer.writeln('- ${p.name}: ${fmt.format(p.amount)} ($status)');
    }
    Share.share(buffer.toString());
  }

  void _confirmDelete(BuildContext context, String id) {
    final s = context.strings;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.confirm),
        content: Text(s.splitbill_delete_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SplitBillBloc>().add(DeleteBillRequested(id));
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

    return BlocBuilder<SplitBillBloc, SplitBillState>(
      builder: (context, state) {
        BillEntity? bill;
        if (state is SplitBillLoaded) {
          for (final b in state.bills) {
            if (b.id == billId) {
              bill = b;
              break;
            }
          }
        }

        if (bill == null) {
          return Scaffold(
            backgroundColor: c.background,
            appBar: NexusAppBar(title: s.splitbill_title),
            body: const SizedBox(),
          );
        }
        final b = bill;

        return Scaffold(
          backgroundColor: c.background,
          appBar: NexusAppBar(
            title: b.title,
            extraActions: [
              IconButton(
                icon: const Icon(CupertinoIcons.share),
                onPressed: () => _share(context, b),
                tooltip: s.splitbill_share,
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.trash),
                onPressed: () => _confirmDelete(context, b.id),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.splitbill_collected.toUpperCase(),
                              style: AppType.label.copyWith(color: c.textSecondary),
                            ),
                            const SizedBox(height: Insets.xs),
                            Text(
                              fmt.format(b.collectedAmount),
                              style: AppType.title.copyWith(color: AppColors.income),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 36, color: c.divider),
                      const SizedBox(width: Insets.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.splitbill_outstanding.toUpperCase(),
                              style: AppType.label.copyWith(color: c.textSecondary),
                            ),
                            const SizedBox(height: Insets.xs),
                            Text(
                              fmt.format(b.outstandingAmount),
                              style: AppType.title.copyWith(
                                color: b.outstandingAmount > 0
                                    ? AppColors.expense
                                    : c.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.lg),
                BlocBuilder<DebtBloc, DebtState>(
                  builder: (context, debtState) {
                    final debts = debtState is DebtLoaded
                        ? debtState.debts
                        : const <DebtEntity>[];
                    if (participantsWithoutDebt(b, debts).isEmpty) {
                      return const SizedBox(height: Insets.md);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Insets.md),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _makeReceivables(context, b),
                          icon: const Icon(CupertinoIcons.arrow_right_arrow_left,
                              size: 18),
                          label: Text(s.link_make_receivable),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding:
                                const EdgeInsets.symmetric(vertical: Insets.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Radii.lg),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                ...b.participants.map(
                  (p) => ParticipantTile(
                    participant: p,
                    onTogglePaid: (isPaid) => _togglePaid(context, b, p.id, isPaid),
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
