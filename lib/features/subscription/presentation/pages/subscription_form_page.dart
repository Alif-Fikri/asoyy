import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../finance/data/recurring_transaction_repository.dart';
import '../../../finance/domain/entities/transaction_entity.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../finance/presentation/widgets/recurring_day_picker_sheet.dart';
import '../../domain/popular_services.dart';

class SubscriptionFormPage extends StatefulWidget {
  const SubscriptionFormPage({super.key});

  @override
  State<SubscriptionFormPage> createState() => _SubscriptionFormPageState();
}

class _SubscriptionFormPageState extends State<SubscriptionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _repo = RecurringTransactionRepository();
  int _dayOfMonth = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  List<String> get _suggestedServices {
    final query = _nameCtrl.text.trim();
    if (popularSubscriptionServices.contains(query)) return const [];
    return popularSubscriptionServices
        .where((service) => service.toLowerCase().contains(query.toLowerCase()))
        .take(6)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    await _repo.add(
      title: _nameCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.replaceAll('.', '')),
      type: TransactionType.expense,
      category: 'Langganan',
      dayOfMonth: _dayOfMonth,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isSubscription: true,
    );
    await _repo.generateDueTransactions(di.sl<FinanceRepository>());

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.subscription_new),
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
                label: s.subscription_service_name,
                controller: _nameCtrl,
                prefixIcon: CupertinoIcons.arrow_2_circlepath,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.required_field : null,
              ),
              if (_suggestedServices.isNotEmpty) ...[
                const SizedBox(height: Insets.sm),
                Wrap(
                  spacing: Insets.sm,
                  runSpacing: Insets.sm,
                  children: _suggestedServices.map((name) {
                    return ActionChip(
                      label: Text(name),
                      onPressed: () {
                        _nameCtrl.text = name;
                        _nameCtrl.selection = TextSelection.collapsed(offset: name.length);
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: Insets.md),
              AppTextField(
                label: s.subscription_amount,
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
              Text(s.subscription_renewal_day, style: TextStyle(color: c.textSecondary, fontSize: 13)),
              const SizedBox(height: Insets.sm),
              InkWell(
                onTap: () async {
                  final picked = await showRecurringDayPicker(context, _dayOfMonth);
                  if (picked != null) setState(() => _dayOfMonth = picked);
                },
                borderRadius: BorderRadius.circular(Radii.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.md),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.calendar, color: AppColors.subscriptionColor, size: 18),
                      const SizedBox(width: Insets.sm),
                      Expanded(
                        child: Text(
                          s.fin_recurring_day_value(_dayOfMonth),
                          style: TextStyle(color: c.textPrimary, fontSize: 14),
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_down, color: c.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Insets.md),
              AppTextField(
                label: '${s.subscription_notes} (${s.optional})',
                controller: _notesCtrl,
                prefixIcon: CupertinoIcons.text_alignleft,
              ),
              const SizedBox(height: Insets.xl),
              AppButton(
                label: s.save,
                onTap: _saving ? null : _submit,
                isLoading: _saving,
                width: double.infinity,
                color: AppColors.subscriptionColor,
                icon: CupertinoIcons.checkmark_alt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
