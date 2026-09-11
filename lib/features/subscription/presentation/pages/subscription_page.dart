import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../../core/widgets/reminder_hint_banner.dart';
import '../../../finance/data/recurring_transaction_repository.dart';
import '../../../finance/domain/entities/recurring_transaction_entity.dart';
import '../../../finance/services/recurring_reminder_service.dart';
import '../widgets/subscription_card.dart';
import 'subscription_form_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _repo = RecurringTransactionRepository();
  final _reminderService = RecurringReminderService();
  late List<RecurringTransactionEntity> _items;

  @override
  void initState() {
    super.initState();
    _items = _repo.getSubscriptions();
  }

  Future<void> _openForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SubscriptionFormPage()),
    );
    if (saved == true) {
      setState(() => _items = _repo.getSubscriptions());
      await _reminderService.rescheduleAll();
      if (mounted) AppToast.show(context, context.strings.subscription_added);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDeleteConfirm(context);
    if (!confirmed) return;
    await _repo.delete(id);
    await _reminderService.cancelReminder(id);
    setState(() => _items = _repo.getSubscriptions());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final monthlyTotal = _items.fold<double>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(
        title: s.subscription_title,
        extraActions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled),
            onPressed: _openForm,
            tooltip: s.subscription_new,
          ),
        ],
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? EmptyStateWidget(
                icon: CupertinoIcons.arrow_2_circlepath,
                title: s.subscription_empty_title,
                subtitle: s.subscription_empty_subtitle,
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.md,
                  Insets.lg,
                  MediaQuery.of(context).padding.bottom + Insets.xxl,
                ),
                children: [
                  ReminderHintBanner(text: s.subscription_reminder_hint),
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
                          s.subscription_monthly_total.toUpperCase(),
                          style: AppType.label.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: Insets.xs),
                        Text(
                          fmt.format(monthlyTotal),
                          style: AppType.display.copyWith(
                            color: AppColors.subscriptionColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  ..._items.map(
                    (item) => SubscriptionCard(
                      subscription: item,
                      onDelete: () => _delete(item.id),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
