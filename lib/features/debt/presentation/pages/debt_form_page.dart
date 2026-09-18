import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/contact_picker.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../domain/entities/debt_entity.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';

class DebtFormPage extends StatefulWidget {
  const DebtFormPage({super.key});

  @override
  State<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends State<DebtFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DebtDirection _direction = DebtDirection.theyOweMe;
  DateTime? _dueDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;

    final debt = DebtEntity(
      id: const Uuid().v4(),
      personName: _nameCtrl.text.trim(),
      amount: amount,
      direction: _direction,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      date: DateTime.now(),
      dueDate: _dueDate,
    );

    context.read<DebtBloc>().add(AddDebtRequested(debt));
    Navigator.pop(context);
  }

  Future<void> _pickContact() async {
    final name = await pickContactName(context);
    if (name != null && name.isNotEmpty) setState(() => _nameCtrl.text = name);
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.debt_new),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.lg,
              Insets.lg,
              MediaQuery.of(context).padding.bottom + Insets.xxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DirectionTab(
                      label: s.debt_owed_to_me,
                      isSelected: _direction == DebtDirection.theyOweMe,
                      color: AppColors.income,
                      onTap: () => setState(() => _direction = DebtDirection.theyOweMe),
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: _DirectionTab(
                      label: s.debt_i_owe,
                      isSelected: _direction == DebtDirection.iOwe,
                      color: AppColors.expense,
                      onTap: () => setState(() => _direction = DebtDirection.iOwe),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.lg),
              AppTextField(
                label: s.debt_person_name,
                controller: _nameCtrl,
                prefixIcon: CupertinoIcons.person,
                suffix: IconButton(
                  icon: Icon(CupertinoIcons.person_crop_circle_badge_plus, color: c.textSecondary),
                  onPressed: _pickContact,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? s.required_field : null,
              ),
              const SizedBox(height: Insets.md),
              AppTextField(
                label: s.debt_amount,
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
              const SizedBox(height: Insets.md),
              AppTextField(
                label: '${s.debt_note} (${s.optional})',
                controller: _noteCtrl,
                prefixIcon: CupertinoIcons.text_alignleft,
              ),
              const SizedBox(height: Insets.md),
              _DueDateField(
                label: '${s.debt_due_date} (${s.optional})',
                value: _dueDate,
                onTap: _pickDueDate,
                onClear: () => setState(() => _dueDate = null),
              ),
              const SizedBox(height: Insets.xl),
              AppButton(
                label: s.save,
                onTap: _submit,
                width: double.infinity,
                color: AppColors.debtColor,
                icon: CupertinoIcons.checkmark_alt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DueDateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.calendar, color: c.textSecondary, size: Sizes.icon),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                value != null ? DateFormat('d MMM yyyy').format(value!) : label,
                style: TextStyle(
                  color: value != null ? c.textPrimary : c.textHint,
                  fontSize: 15,
                ),
              ),
            ),
            if (value != null)
              IconButton(
                icon: Icon(CupertinoIcons.clear_circled_solid, color: c.textSecondary, size: 18),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}

class _DirectionTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _DirectionTab({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Insets.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : c.cardLight,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: isSelected ? color : c.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : c.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
