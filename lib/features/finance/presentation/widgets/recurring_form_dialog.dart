import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/finance_category_repository.dart';
import '../../domain/entities/transaction_entity.dart';
import 'recurring_day_picker_sheet.dart';

class RecurringFormDialog extends StatefulWidget {
  final Future<void> Function({
    required String title,
    required double amount,
    required TransactionType type,
    required String category,
    required int dayOfMonth,
    String? notes,
  }) onSave;

  const RecurringFormDialog({super.key, required this.onSave});

  @override
  State<RecurringFormDialog> createState() => _RecurringFormDialogState();
}

class _RecurringFormDialogState extends State<RecurringFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _categoryRepo = FinanceCategoryRepository();
  TransactionType _type = TransactionType.expense;
  int _dayOfMonth = 1;
  late String _category;
  bool _categoryInitialized = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSave(
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.replaceAll('.', '')),
      type: _type,
      category: _category,
      dayOfMonth: _dayOfMonth,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final isIncome = _type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final categories = _categories(s);

    if (!_categoryInitialized) {
      _category = categories.first;
      _categoryInitialized = true;
    }

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
                s.fin_recurring_add,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = TransactionType.expense;
                          _category = _expenseCategories(s).first;
                        }),
                        child: _TypeTabContent(
                          label: s.fin_expense,
                          icon: CupertinoIcons.arrow_up,
                          isSelected: _type == TransactionType.expense,
                          color: AppColors.expense,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = TransactionType.income;
                          _category = _incomeCategories(s).first;
                        }),
                        child: _TypeTabContent(
                          label: s.fin_income,
                          icon: CupertinoIcons.arrow_down,
                          isSelected: _type == TransactionType.income,
                          color: AppColors.income,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: s.fin_description,
                controller: _titleCtrl,
                prefixIcon: CupertinoIcons.doc_text,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.required_field : null,
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
                  if (double.tryParse(v.replaceAll('.', '')) == null) {
                    return s.invalid_number;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(s.fin_category, style: TextStyle(color: c.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: c.card,
                    style: TextStyle(color: c.textPrimary, fontSize: 14),
                    items: categories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(s.fin_recurring_day_label,
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked =
                      await showRecurringDayPicker(context, _dayOfMonth);
                  if (picked != null) setState(() => _dayOfMonth = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.calendar, color: color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.fin_recurring_day_value(_dayOfMonth),
                          style: TextStyle(color: c.textPrimary, fontSize: 14),
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_down,
                          color: c.textSecondary, size: 16),
                    ],
                  ),
                ),
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

class _TypeTabContent extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;

  const _TypeTabContent({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
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
    );
  }
}
