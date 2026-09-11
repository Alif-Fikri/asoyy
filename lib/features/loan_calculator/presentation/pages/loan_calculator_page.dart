import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../domain/loan_calc.dart';

class LoanCalculatorPage extends StatefulWidget {
  const LoanCalculatorPage({super.key});

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController(text: '6');
  final _tenorCtrl = TextEditingController(text: '12');
  LoanInterestMethod _method = LoanInterestMethod.annuity;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _tenorCtrl.dispose();
    super.dispose();
  }

  double _parse(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0;

  double _parseAmount(String text) => double.tryParse(text.replaceAll('.', '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final principal = _parseAmount(_amountCtrl.text);
    final rate = _parse(_rateCtrl.text);
    final tenor = int.tryParse(_tenorCtrl.text) ?? 0;
    final result = calculateLoan(
      principal: principal,
      annualRatePercent: rate,
      tenorMonths: tenor,
      method: _method,
    );

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.loan_calc_title),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.md,
            Insets.lg,
            MediaQuery.of(context).padding.bottom + Insets.xxl,
          ),
          children: [
            AppTextField(
              label: s.loan_calc_amount,
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: CupertinoIcons.money_dollar,
              inputFormatters: [ThousandSeparatorFormatter()],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Insets.md),
            AppTextField(
              label: s.loan_calc_rate,
              hint: s.loan_calc_rate_hint,
              controller: _rateCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: CupertinoIcons.percent,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Insets.md),
            AppTextField(
              label: s.loan_calc_tenor,
              hint: s.loan_calc_tenor_hint,
              controller: _tenorCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: CupertinoIcons.calendar,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Insets.lg),
            Text(
              s.loan_calc_method.toUpperCase(),
              style: AppType.label.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: Insets.sm,
              children: [
                AppChip(
                  label: s.loan_calc_method_annuity,
                  isSelected: _method == LoanInterestMethod.annuity,
                  color: AppColors.loanCalcColor,
                  onTap: () => setState(() => _method = LoanInterestMethod.annuity),
                ),
                AppChip(
                  label: s.loan_calc_method_flat,
                  isSelected: _method == LoanInterestMethod.flat,
                  color: AppColors.loanCalcColor,
                  onTap: () => setState(() => _method = LoanInterestMethod.flat),
                ),
              ],
            ),
            const SizedBox(height: Insets.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Insets.lg),
              decoration: BoxDecoration(
                color: AppColors.loanCalcColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(
                  color: AppColors.loanCalcColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.loan_calc_monthly_installment.toUpperCase(),
                    style: AppType.label.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: Insets.xs),
                  Text(
                    fmt.format(result.monthlyInstallment),
                    style: AppType.display.copyWith(color: AppColors.loanCalcColor),
                  ),
                  const SizedBox(height: Insets.lg),
                  _ResultRow(
                    label: s.loan_calc_total_interest,
                    value: fmt.format(result.totalInterest),
                  ),
                  const SizedBox(height: Insets.sm),
                  _ResultRow(
                    label: s.loan_calc_total_payment,
                    value: fmt.format(result.totalPayment),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.md),
            Text(
              s.loan_calc_disclaimer,
              style: AppType.caption.copyWith(color: c.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppType.body.copyWith(color: c.textSecondary)),
        Text(
          value,
          style: AppType.body.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
