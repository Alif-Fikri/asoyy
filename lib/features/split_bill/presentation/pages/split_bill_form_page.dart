import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../domain/entities/bill_entity.dart';
import '../bloc/split_bill_bloc.dart';
import '../bloc/split_bill_event.dart';

class SplitBillFormPage extends StatefulWidget {
  const SplitBillFormPage({super.key});

  @override
  State<SplitBillFormPage> createState() => _SplitBillFormPageState();
}

class _ParticipantInput {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
  }
}

class _SplitBillFormPageState extends State<SplitBillFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  bool _splitEqually = true;
  String? _errorText;

  final List<_ParticipantInput> _participants = [
    _ParticipantInput(),
    _ParticipantInput(),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _totalCtrl.dispose();
    for (final p in _participants) {
      p.dispose();
    }
    super.dispose();
  }

  double? get _totalAmount => double.tryParse(_totalCtrl.text.replaceAll('.', ''));

  void _addParticipant() {
    setState(() => _participants.add(_ParticipantInput()));
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants[index].dispose();
      _participants.removeAt(index);
    });
  }

  void _submit() {
    setState(() => _errorText = null);
    if (!_formKey.currentState!.validate()) return;

    final total = _totalAmount;
    if (total == null || total <= 0) {
      setState(() => _errorText = context.strings.invalid_number);
      return;
    }
    if (_participants.length < 2) {
      setState(() => _errorText = context.strings.splitbill_min_participants);
      return;
    }

    final names = _participants.map((p) => p._nameCtrl.text.trim()).toList();

    List<ParticipantEntity> participants;
    if (_splitEqually) {
      final share = total / names.length;
      participants = names
          .map((name) => ParticipantEntity(id: const Uuid().v4(), name: name, amount: share))
          .toList();
    } else {
      final amounts = _participants
          .map((p) => double.tryParse(p._amountCtrl.text.replaceAll('.', '')) ?? 0)
          .toList();
      final sum = amounts.fold<double>(0, (s, a) => s + a);
      if ((sum - total).abs() > 1) {
        setState(() => _errorText = context.strings.splitbill_amount_mismatch);
        return;
      }
      participants = List.generate(
        names.length,
        (i) => ParticipantEntity(id: const Uuid().v4(), name: names[i], amount: amounts[i]),
      );
    }

    final bill = BillEntity(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      totalAmount: total,
      date: DateTime.now(),
      participants: participants,
      splitEqually: _splitEqually,
    );

    context.read<SplitBillBloc>().add(AddBillRequested(bill));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.splitbill_new_bill),
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
              AppTextField(
                label: s.splitbill_bill_name,
                controller: _titleCtrl,
                prefixIcon: CupertinoIcons.doc_text,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.required_field : null,
              ),
              const SizedBox(height: Insets.md),
              AppTextField(
                label: s.splitbill_total_amount,
                controller: _totalCtrl,
                prefixIcon: CupertinoIcons.money_dollar,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandSeparatorFormatter()],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return s.required_field;
                  if (double.tryParse(v.replaceAll('.', '')) == null) return s.invalid_number;
                  return null;
                },
              ),
              const SizedBox(height: Insets.lg),
              Row(
                children: [
                  Expanded(
                    child: _SplitModeTab(
                      label: s.splitbill_equal_split,
                      isSelected: _splitEqually,
                      onTap: () => setState(() => _splitEqually = true),
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: _SplitModeTab(
                      label: s.splitbill_custom_split,
                      isSelected: !_splitEqually,
                      onTap: () => setState(() => _splitEqually = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.lg),
              ...List.generate(_participants.length, (i) {
                final p = _participants[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: Insets.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: '${s.splitbill_participant_name} ${i + 1}',
                          controller: p._nameCtrl,
                          prefixIcon: CupertinoIcons.person,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? s.required_field : null,
                        ),
                      ),
                      if (!_splitEqually) ...[
                        const SizedBox(width: Insets.sm),
                        Expanded(
                          child: AppTextField(
                            label: s.splitbill_total_amount,
                            controller: p._amountCtrl,
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
                        ),
                      ],
                      if (_participants.length > 2)
                        IconButton(
                          icon: Icon(CupertinoIcons.trash, color: c.textSecondary),
                          onPressed: () => _removeParticipant(i),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addParticipant,
                icon: const Icon(CupertinoIcons.add, color: AppColors.splitBillColor),
                label: Text(
                  s.splitbill_add_participant,
                  style: const TextStyle(color: AppColors.splitBillColor),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: Insets.sm),
                Text(
                  _errorText!,
                  style: const TextStyle(color: AppColors.expense, fontSize: 13),
                ),
              ],
              const SizedBox(height: Insets.xl),
              AppButton(
                label: s.save,
                onTap: _submit,
                width: double.infinity,
                color: AppColors.splitBillColor,
                icon: CupertinoIcons.checkmark_alt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SplitModeTab({
    required this.label,
    required this.isSelected,
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
          color: isSelected
              ? AppColors.splitBillColor.withValues(alpha: 0.12)
              : c.cardLight,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: isSelected ? AppColors.splitBillColor : c.border,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.splitBillColor : c.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
