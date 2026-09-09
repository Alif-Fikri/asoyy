import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/recurring_transaction_repository.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../services/recurring_reminder_service.dart';
import '../widgets/recurring_form_dialog.dart';

class RecurringTransactionsPage extends StatefulWidget {
  final VoidCallback onChanged;

  const RecurringTransactionsPage({super.key, required this.onChanged});

  @override
  State<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends State<RecurringTransactionsPage> {
  final _repo = RecurringTransactionRepository();
  final _reminderService = RecurringReminderService();
  late List<RecurringTransactionEntity> _items;

  @override
  void initState() {
    super.initState();
    _items = _repo.getAll();
  }

  Future<void> _add() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecurringFormDialog(
        onSave: ({
          required title,
          required amount,
          required type,
          required category,
          required dayOfMonth,
          notes,
        }) async {
          await _repo.add(
            title: title,
            amount: amount,
            type: type,
            category: category,
            dayOfMonth: dayOfMonth,
            notes: notes,
          );
          await _repo.generateDueTransactions(di.sl<FinanceRepository>());
        },
      ),
    );
    setState(() => _items = _repo.getAll());
    await _reminderService.rescheduleAll();
    widget.onChanged();
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDeleteConfirm(context);
    if (!confirmed) return;
    await _repo.delete(id);
    await _reminderService.cancelReminder(id);
    setState(() => _items = _repo.getAll());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(
        title: s.fin_recurring_title,
        extraActions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle),
            onPressed: _add,
            tooltip: s.fin_recurring_add,
          ),
        ],
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? EmptyStateWidget(
                icon: CupertinoIcons.repeat,
                title: s.fin_recurring_empty_title,
                subtitle: s.fin_recurring_empty_subtitle,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                children: [
                  IosSection(
                    children: _items.map((item) {
                      final fmt = NumberFormat.decimalPattern('id_ID');
                      final color = item.isIncome
                          ? AppColors.income
                          : AppColors.expense;
                      return IosRow(
                        leading: IosIcon(
                          icon: item.isIncome
                              ? CupertinoIcons.arrow_down_circle_fill
                              : CupertinoIcons.arrow_up_circle_fill,
                          color: color,
                        ),
                        title: item.title,
                        subtitle:
                            '${item.category} · ${s.fin_recurring_day_value(item.dayOfMonth)}',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rp ${fmt.format(item.amount)}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _delete(item.id),
                              child: Icon(CupertinoIcons.trash,
                                  size: 18, color: c.textHint),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
      ),
    );
  }
}
