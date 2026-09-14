import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../data/account_repository.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/utils/account_balance.dart';
import '../../../../core/widgets/action_sheet.dart';
import '../widgets/account_picker.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_state.dart';
import '../widgets/account_visuals.dart';

class AccountsPage extends StatefulWidget {
  final VoidCallback onChanged;
  final void Function(String fromId, String toId) onReassign;

  const AccountsPage({
    super.key,
    required this.onChanged,
    required this.onReassign,
  });

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final _repo = AccountRepository();
  late List<AccountEntity> _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = _repo.getAll();
  }

  void _reload() {
    setState(() => _accounts = _repo.getAll());
    widget.onChanged();
  }

  List<TransactionEntity> _transactions(BuildContext context) {
    final state = context.read<FinanceBloc>().state;
    return state is FinanceLoaded ? state.all : const [];
  }

  int _usageCount(String accountId) => _transactions(context)
      .where((t) => t.accountId == accountId || t.toAccountId == accountId)
      .length;

  Future<void> _openForm({AccountEntity? existing}) async {
    final saved = await showModalBottomSheet<AccountEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountFormSheet(existing: existing),
    );
    if (saved == null || !mounted) return;
    await _repo.save(saved);
    if (!mounted) return;
    AppToast.show(context, context.strings.acc_saved);
    _reload();
  }

  Future<void> _delete(AccountEntity account) async {
    final s = context.strings;
    final used = _usageCount(account.id);

    if (used == 0) {
      final confirmed = await showDeleteConfirm(context);
      if (!confirmed || !mounted) return;
      await _repo.delete(account.id);
      if (!mounted) return;
      AppToast.show(context, s.acc_deleted);
      _reload();
      return;
    }

    final others =
        _accounts.where((a) => a.id != account.id).toList(growable: false);
    final choice = await showActionSheet<String>(
      context,
      title: s.acc_delete_in_use_title(used),
      actions: [
        if (others.isNotEmpty)
          SheetAction(
            value: 'move',
            icon: CupertinoIcons.arrow_right_arrow_left,
            color: AppColors.primary,
            label: s.acc_delete_move,
            subtitle: s.acc_delete_move_desc,
          )
        else
          SheetAction(
            value: 'none',
            icon: CupertinoIcons.info,
            color: AppColors.calendarColor,
            label: s.acc_delete_needs_target,
          ),
        SheetAction(
          value: 'delete',
          icon: CupertinoIcons.trash,
          color: AppColors.alarmColor,
          label: s.acc_delete_anyway,
          subtitle: s.acc_delete_anyway_desc,
        ),
      ],
    );
    if (choice == null || choice == 'none' || !mounted) return;

    if (choice == 'move') {
      final target = await showAccountPicker(context, others, null);
      if (target == null || !mounted) return;
      widget.onReassign(account.id, target.id);
      await _repo.delete(account.id);
      if (!mounted) return;
      AppToast.show(context, s.acc_moved(used));
      _reload();
      return;
    }

    final confirmed = await showDeleteConfirm(context);
    if (!confirmed || !mounted) return;
    await _repo.delete(account.id);
    if (!mounted) return;
    AppToast.show(context, s.acc_deleted);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) => _buildScaffold(
        context,
        state is FinanceLoaded ? state.all : const [],
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<TransactionEntity> transactions,
  ) {
    final c = context.colors;
    final s = context.strings;
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final balances = balanceByAccount(_accounts, transactions);
    final total = totalBalance(_accounts, transactions);

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(
        title: s.acc_title,
        extraActions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle),
            onPressed: () => _openForm(),
            tooltip: s.acc_add,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
          children: [
            IosSection(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.all(Insets.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.acc_total.toUpperCase(),
                        style: AppType.label.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: Insets.sm),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          fmt.format(total),
                          style: AppType.display.copyWith(
                            color: total >= 0
                                ? c.textPrimary
                                : AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: EmptyStateWidget(
                  icon: CupertinoIcons.creditcard,
                  title: s.acc_empty_title,
                  subtitle: s.acc_empty_subtitle,
                ),
              )
            else
              IosSection(
                children: _accounts
                    .map(
                      (a) => _AccountTile(
                        account: a,
                        balance: balances[a.id] ?? 0,
                        formatter: fmt,
                        onTap: () => _openForm(existing: a),
                        onLongPress: () => _delete(a),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AccountEntity account;
  final double balance;
  final NumberFormat formatter;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AccountTile({
    required this.account,
    required this.balance,
    required this.formatter,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final color = accountColor(account.type);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
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
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(accountIcon(account.type), color: color, size: 18),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: AppType.bodyStrong.copyWith(color: c.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    accountTypeLabel(account.type, s),
                    style: AppType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Insets.sm),
            Text(
              formatter.format(balance),
              style: AppType.bodyStrong.copyWith(
                color: balance >= 0 ? c.textPrimary : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountFormSheet extends StatefulWidget {
  final AccountEntity? existing;
  const _AccountFormSheet({this.existing});

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late AccountType _type;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    final initial = widget.existing?.initialBalance ?? 0;
    _balanceCtrl = TextEditingController(
      text: initial == 0 ? '' : NumberFormat.decimalPattern('id_ID').format(initial),
    );
    _type = widget.existing?.type ?? AccountType.cash;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final raw = _balanceCtrl.text.replaceAll('.', '').trim();
    Navigator.pop(
      context,
      AccountEntity(
        id: widget.existing?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        type: _type,
        initialBalance: raw.isEmpty ? 0 : double.parse(raw),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.existing == null ? s.acc_add : s.acc_edit,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: s.acc_name,
                controller: _nameCtrl,
                prefixIcon: CupertinoIcons.creditcard,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.required_field : null,
              ),
              const SizedBox(height: 12),
              Text(
                s.acc_type,
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: Insets.sm,
                runSpacing: Insets.sm,
                children: AccountType.values
                    .map(
                      (t) => _TypeChip(
                        label: accountTypeLabel(t, s),
                        icon: accountIcon(t),
                        color: accountColor(t),
                        selected: _type == t,
                        onTap: () => setState(() => _type = t),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: s.acc_initial_balance,
                controller: _balanceCtrl,
                prefixIcon: CupertinoIcons.money_dollar,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandSeparatorFormatter()],
              ),
              const SizedBox(height: 24),
              AppButton(
                label: s.save,
                onTap: _submit,
                width: double.infinity,
                icon: CupertinoIcons.check_mark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : c.card,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: selected ? color : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : c.textSecondary),
            const SizedBox(width: Insets.xs),
            Text(
              label,
              style: AppType.caption.copyWith(
                color: selected ? color : c.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
