import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/resizable_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/account_repository.dart';
import '../../data/finance_category_repository.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../../../core/widgets/action_sheet.dart';
import '../../services/receipt_scanner.dart';
import 'account_picker.dart';

class TransactionFormDialog extends StatefulWidget {
  final void Function(TransactionEntity) onSave;
  final int Function(String category) categoryUsageCount;
  final TransactionEntity? existing;

  const TransactionFormDialog({
    super.key,
    required this.onSave,
    required this.categoryUsageCount,
    this.existing,
  });

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _categoryRepo = FinanceCategoryRepository();
  final _accountRepo = AccountRepository();
  TransactionType _type = TransactionType.expense;
  late String _category;
  bool _categoryInitialized = false;
  late List<AccountEntity> _accounts;
  String? _accountId;
  String? _toAccountId;
  String? _accountError;
  DateTime? _scannedDate;
  bool _scanning = false;

  Future<void> _scanReceipt() async {
    final s = context.strings;
    final source = await showActionSheet<bool>(
      context,
      title: s.scan_receipt,
      actions: [
        SheetAction(
          value: true,
          icon: CupertinoIcons.camera,
          color: AppColors.primary,
          label: s.scan_camera,
        ),
        SheetAction(
          value: false,
          icon: CupertinoIcons.photo,
          color: AppColors.calendarColor,
          label: s.scan_gallery,
        ),
      ],
    );
    if (source == null || !mounted) return;

    setState(() => _scanning = true);
    try {
      final scan = await ReceiptScanner().scan(fromCamera: source);
      if (!mounted) return;
      if (scan == null) return;

      if (scan.isEmpty) {
        AppToast.show(context, s.scan_nothing_found);
        return;
      }

      setState(() {
        _type = TransactionType.expense;
        if (scan.total != null) {
          _amountCtrl.text =
              NumberFormat.decimalPattern('id_ID').format(scan.total);
        }
        if (scan.merchant != null) _titleCtrl.text = scan.merchant!;
        if (scan.category != null) {
          _category = scan.category!;
          _categoryInitialized = true;
        }
        _scannedDate = scan.date;
      });
      AppToast.show(context, s.scan_check_result);
    } catch (_) {
      if (mounted) AppToast.show(context, s.scan_nothing_found);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _accounts = _accountRepo.getAll();

    final existing = widget.existing;
    if (existing == null) {
      _accountId = _accountRepo.fallbackAccountId ??
          (_accounts.isNotEmpty ? _accounts.first.id : null);
      return;
    }

    _titleCtrl.text = existing.title;
    _amountCtrl.text =
        NumberFormat.decimalPattern('id_ID').format(existing.amount);
    _notesCtrl.text = existing.notes ?? '';
    _type = existing.type;
    _accountId = existing.accountId;
    _toAccountId = existing.toAccountId;
    if (existing.type != TransactionType.transfer) {
      _category = existing.category;
      _categoryInitialized = true;
    }
  }

  AccountEntity? _accountById(String? id) {
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> _pickAccount({required bool target}) async {
    final picked = await showAccountPicker(
      context,
      _accounts,
      target ? _toAccountId : _accountId,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (target) {
        _toAccountId = picked.id;
      } else {
        _accountId = picked.id;
      }
      _accountError = null;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  List<String> _incomeCategories(AppStrings s) => [
    s.cat_salary, s.cat_freelance, s.cat_investment, s.cat_bonus, s.cat_gift, s.cat_other,
  ];

  List<String> _expenseCategories(AppStrings s) => [
    s.cat_food, s.cat_transport, s.cat_shopping, s.cat_bills, s.cat_health,
    s.cat_entertainment, s.cat_education, s.cat_other,
  ];

  List<String> _defaultCategories(AppStrings s, TransactionType type) =>
      type == TransactionType.income
          ? _incomeCategories(s)
          : _expenseCategories(s);

  List<String> _categories(AppStrings s) => [
        ..._categoryRepo.visibleDefaults(_type, _defaultCategories(s, _type)),
        ..._categoryRepo.getCustom(_type),
      ];

  Future<void> _openCategoryPicker() async {
    final color = _type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerSheet(
        type: _type,
        selected: _category,
        color: color,
        repo: _categoryRepo,
        allDefaults: _defaultCategories(context.strings, _type),
        categoryUsageCount: widget.categoryUsageCount,
      ),
    );
    if (result != null && mounted) setState(() => _category = result);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_type == TransactionType.transfer) {
      if (_accountId == null ||
          _toAccountId == null ||
          _accountId == _toAccountId) {
        setState(() => _accountError = context.strings.fin_transfer_same_account);
        return;
      }
    }

    widget.onSave(TransactionEntity(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.replaceAll('.', '')),
      type: _type,
      category: _type == TransactionType.transfer ? transferCategory : _category,
      date: widget.existing?.date ?? _scannedDate ?? DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      accountId: _accountId,
      toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final color = switch (_type) {
      TransactionType.income => AppColors.income,
      TransactionType.expense => AppColors.expense,
      TransactionType.transfer => AppColors.primary,
    };
    final categories = _categories(s);

    if (!_categoryInitialized) {
      _category = categories.first;
      _categoryInitialized = true;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom + 24),
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(widget.existing == null ? s.fin_add : s.fin_edit,
                        style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ),
                  if (widget.existing == null)
                    _scanning
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton.icon(
                            onPressed: _scanReceipt,
                            icon: const Icon(CupertinoIcons.camera, size: 18),
                            label: Text(s.scan_receipt),
                          ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    _TypeTab(
                      label: s.fin_expense,
                      icon: CupertinoIcons.arrow_up,
                      isSelected: _type == TransactionType.expense,
                      color: AppColors.expense,
                      onTap: () => setState(() {
                        _type = TransactionType.expense;
                        _category = _expenseCategories(s).first;
                      }),
                    ),
                    _TypeTab(
                      label: s.fin_income,
                      icon: CupertinoIcons.arrow_down,
                      isSelected: _type == TransactionType.income,
                      color: AppColors.income,
                      onTap: () => setState(() {
                        _type = TransactionType.income;
                        _category = _incomeCategories(s).first;
                      }),
                    ),
                    _TypeTab(
                      label: s.fin_transfer,
                      icon: CupertinoIcons.arrow_right_arrow_left,
                      isSelected: _type == TransactionType.transfer,
                      color: AppColors.primary,
                      onTap: () => setState(() {
                        _type = TransactionType.transfer;
                        _accountError = null;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: s.fin_description,
                controller: _titleCtrl,
                prefixIcon: CupertinoIcons.doc_text,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.required_field : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: s.fin_amount,
                controller: _amountCtrl,
                prefixIcon: CupertinoIcons.money_dollar,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandSeparatorFormatter()],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return s.required_field;
                  if (double.tryParse(v.replaceAll('.', '')) == null) return s.invalid_number;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_type == TransactionType.transfer) ...[
                AccountField(
                  label: s.fin_from,
                  account: _accountById(_accountId),
                  onTap: () => _pickAccount(target: false),
                ),
                const SizedBox(height: 12),
                AccountField(
                  label: s.fin_to,
                  account: _accountById(_toAccountId),
                  onTap: () => _pickAccount(target: true),
                ),
              ] else
                AccountField(
                  label: s.fin_account,
                  account: _accountById(_accountId),
                  onTap: () => _pickAccount(target: false),
                ),
              if (_accountError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _accountError!,
                  style: const TextStyle(
                      color: AppColors.alarmColor, fontSize: 13),
                ),
              ],
              if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 12),
              Text(s.fin_category, style: TextStyle(color: c.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _openCategoryPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.tag, color: color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _category,
                          style: TextStyle(color: c.textPrimary, fontSize: 14),
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_down,
                          color: c.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),
              ],
              const SizedBox(height: 12),
              ResizableTextField(
                label: s.fin_notes,
                controller: _notesCtrl,
                prefixIcon: CupertinoIcons.text_alignleft,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: s.fin_save,
                onTap: _submit,
                width: double.infinity,
                color: color,
                icon: CupertinoIcons.check_mark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  final TransactionType type;
  final String selected;
  final Color color;
  final FinanceCategoryRepository repo;
  final List<String> allDefaults;
  final int Function(String category) categoryUsageCount;

  const _CategoryPickerSheet({
    required this.type,
    required this.selected,
    required this.color,
    required this.repo,
    required this.allDefaults,
    required this.categoryUsageCount,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late List<String> _custom;
  late List<String> _visibleDefaults;
  late String _selected;

  @override
  void initState() {
    super.initState();
    _custom = widget.repo.getCustom(widget.type);
    _visibleDefaults = widget.repo.visibleDefaults(widget.type, widget.allDefaults);
    _selected = widget.selected;
  }

  Future<void> _addCategory() async {
    final s = context.strings;
    final controller = TextEditingController();
    final all = [..._visibleDefaults, ..._custom];
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.fin_add_category),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: s.fin_category_name_hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    if (all.contains(name)) {
      AppToast.show(context, s.fin_category_exists);
      return;
    }
    await widget.repo.add(widget.type, name);
    if (!mounted) return;
    setState(() => _custom = widget.repo.getCustom(widget.type));
    AppToast.show(context, s.fin_category_added);
    Navigator.pop(context, name);
  }

  Future<void> _deleteCategory(String name, {required bool isDefault}) async {
    final s = context.strings;
    final usage = widget.categoryUsageCount(name);
    if (usage > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.fin_category_in_use_title),
          content: Text(s.fin_category_in_use_desc(usage)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.close),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.fin_delete_category_title),
        content: Text(s.fin_delete_category_warning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.alarmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (isDefault) {
      await widget.repo.hideDefault(widget.type, name);
    } else {
      await widget.repo.remove(widget.type, name);
    }
    if (!mounted) return;
    setState(() {
      _custom = widget.repo.getCustom(widget.type);
      _visibleDefaults =
          widget.repo.visibleDefaults(widget.type, widget.allDefaults);
      if (_selected == name) {
        final remaining = [..._visibleDefaults, ..._custom];
        _selected = remaining.isNotEmpty ? remaining.first : '';
      }
    });
    AppToast.show(context, s.fin_category_deleted);
    if (name == widget.selected && _selected != name) {
      Navigator.pop(context, _selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final all = [..._visibleDefaults, ..._custom];

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                s.fin_category,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addCategory,
                icon: Icon(CupertinoIcons.add, size: 16, color: widget.color),
                label: Text(
                  s.fin_add_category,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: all.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: c.divider),
              itemBuilder: (ctx, i) {
                final cat = all[i];
                final isDefault = i < _visibleDefaults.length;
                final isSelected = cat == _selected;
                return ListTile(
                  onTap: () => Navigator.pop(context, cat),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? CupertinoIcons.checkmark_alt_circle_fill
                        : CupertinoIcons.circle,
                    color: isSelected ? widget.color : c.textHint,
                    size: 20,
                  ),
                  title: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? widget.color : c.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(CupertinoIcons.trash,
                        size: 18, color: c.textHint),
                    onPressed: () =>
                        _deleteCategory(cat, isDefault: isDefault),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : c.textHint, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : c.textHint,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
