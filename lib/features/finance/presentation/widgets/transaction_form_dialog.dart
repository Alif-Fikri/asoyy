import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionFormDialog extends StatefulWidget {
  final void Function(TransactionEntity) onSave;

  const TransactionFormDialog({super.key, required this.onSave});

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  late String _category;
  bool _categoryInitialized = false;

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

  List<String> _categories(AppStrings s) => _type == TransactionType.income
      ? _incomeCategories(s)
      : _expenseCategories(s);

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(TransactionEntity(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.replaceAll('.', '')),
      type: _type,
      category: _category,
      date: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    ));
    Navigator.pop(context);
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
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
              Text(s.fin_add,
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
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
              Text(s.fin_category, style: TextStyle(color: c.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final selected = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? color.withValues(alpha: 0.15) : c.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? color : c.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected ? color : c.textSecondary,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: s.fin_notes,
                controller: _notesCtrl,
                prefixIcon: CupertinoIcons.text_alignleft,
                maxLines: 2,
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
