import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../../core/widgets/segmented_tab_bar.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../domain/kpr_calc.dart';
import '../../domain/loan_calc.dart';

enum _CalcMode { installment, rate, kpr }

class LoanCalculatorPage extends StatefulWidget {
  const LoanCalculatorPage({super.key});

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController(text: '6');
  final _tenorCtrl = TextEditingController(text: '12');
  final _installmentCtrl = TextEditingController();
  LoanInterestMethod _method = LoanInterestMethod.annuity;
  _CalcMode _mode = _CalcMode.installment;

  final _propertyPriceCtrl = TextEditingController();
  final _dpPercentCtrl = TextEditingController(text: '20');
  final _fixedRateCtrl = TextEditingController(text: '6');
  final _fixedYearsCtrl = TextEditingController(text: '3');
  final _floatingRateCtrl = TextEditingController(text: '11');
  final _kprTenorYearsCtrl = TextEditingController(text: '15');
  final _incomeCtrl = TextEditingController();
  final _otherInstallmentCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _tenorCtrl.dispose();
    _installmentCtrl.dispose();
    _propertyPriceCtrl.dispose();
    _dpPercentCtrl.dispose();
    _fixedRateCtrl.dispose();
    _fixedYearsCtrl.dispose();
    _floatingRateCtrl.dispose();
    _kprTenorYearsCtrl.dispose();
    _incomeCtrl.dispose();
    _otherInstallmentCtrl.dispose();
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
    final tenor = int.tryParse(_tenorCtrl.text) ?? 0;

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
            Text(
              s.loan_calc_mode.toUpperCase(),
              style: AppType.label.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: Insets.sm),
            SegmentedTabBar<_CalcMode>(
              selected: _mode,
              color: AppColors.loanCalcColor,
              onChanged: (mode) => setState(() => _mode = mode),
              tabs: [
                SegmentedTab(value: _CalcMode.installment, label: s.loan_calc_mode_installment),
                SegmentedTab(value: _CalcMode.rate, label: s.loan_calc_mode_rate),
                SegmentedTab(value: _CalcMode.kpr, label: s.loan_calc_mode_kpr),
              ],
            ),
            const SizedBox(height: Insets.lg),
            if (_mode == _CalcMode.kpr) ...[
              _buildKprInputs(context, c, s),
              const SizedBox(height: Insets.xl),
              _KprResultCard(
                propertyPrice: _parseAmount(_propertyPriceCtrl.text),
                dpPercent: _parse(_dpPercentCtrl.text),
                fixedRatePercent: _parse(_fixedRateCtrl.text),
                fixedYears: int.tryParse(_fixedYearsCtrl.text) ?? 0,
                floatingRatePercent: _parse(_floatingRateCtrl.text),
                tenorYears: int.tryParse(_kprTenorYearsCtrl.text) ?? 0,
                method: _method,
                monthlyIncome: _parseAmount(_incomeCtrl.text),
                otherInstallments: _parseAmount(_otherInstallmentCtrl.text),
                fmt: fmt,
                s: s,
              ),
              const SizedBox(height: Insets.md),
              Text(
                s.loan_calc_disclaimer,
                style: AppType.caption.copyWith(color: c.textSecondary, height: 1.4),
              ),
            ] else
              ..._buildGenericLoanBody(context, c, s, fmt, principal, tenor),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGenericLoanBody(
    BuildContext context,
    AppColorTheme c,
    AppStrings s,
    NumberFormat fmt,
    double principal,
    int tenor,
  ) {
    return [
            AppTextField(
              label: s.loan_calc_amount,
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: CupertinoIcons.money_dollar,
              inputFormatters: [ThousandSeparatorFormatter()],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Insets.md),
            if (_mode == _CalcMode.installment)
              AppTextField(
                label: s.loan_calc_rate,
                hint: s.loan_calc_rate_hint,
                controller: _rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: CupertinoIcons.percent,
                onChanged: (_) => setState(() {}),
              )
            else
              AppTextField(
                label: s.loan_calc_known_installment,
                controller: _installmentCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: CupertinoIcons.money_dollar,
                inputFormatters: [ThousandSeparatorFormatter()],
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
            SegmentedTabBar<LoanInterestMethod>(
              selected: _method,
              color: AppColors.loanCalcColor,
              onChanged: (method) => setState(() => _method = method),
              tabs: [
                SegmentedTab(value: LoanInterestMethod.annuity, label: s.loan_calc_method_annuity),
                SegmentedTab(value: LoanInterestMethod.flat, label: s.loan_calc_method_flat),
              ],
            ),
            const SizedBox(height: Insets.xl),
            if (_mode == _CalcMode.installment)
              _InstallmentResultCard(
                result: calculateLoan(
                  principal: principal,
                  annualRatePercent: _parse(_rateCtrl.text),
                  tenorMonths: tenor,
                  method: _method,
                ),
                fmt: fmt,
                s: s,
              )
            else
              _RateResultCard(
                result: solveLoanRate(
                  principal: principal,
                  monthlyInstallment: _parseAmount(_installmentCtrl.text),
                  tenorMonths: tenor,
                  method: _method,
                ),
                fmt: fmt,
                s: s,
              ),
            const SizedBox(height: Insets.md),
            Text(
              s.loan_calc_disclaimer,
              style: AppType.caption.copyWith(color: c.textSecondary, height: 1.4),
            ),
    ];
  }

  Widget _buildKprInputs(BuildContext context, AppColorTheme c, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: s.loan_calc_property_price,
          controller: _propertyPriceCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: CupertinoIcons.house,
          inputFormatters: [ThousandSeparatorFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Insets.md),
        AppTextField(
          label: s.loan_calc_down_payment_percent,
          controller: _dpPercentCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: CupertinoIcons.percent,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Insets.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: s.loan_calc_fixed_rate,
                controller: _fixedRateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: CupertinoIcons.percent,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: AppTextField(
                label: s.loan_calc_fixed_years,
                hint: s.loan_calc_fixed_years_hint,
                controller: _fixedYearsCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: CupertinoIcons.calendar,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        AppTextField(
          label: s.loan_calc_floating_rate,
          controller: _floatingRateCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: CupertinoIcons.percent,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Insets.md),
        AppTextField(
          label: s.loan_calc_tenor_years,
          controller: _kprTenorYearsCtrl,
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
        SegmentedTabBar<LoanInterestMethod>(
          selected: _method,
          color: AppColors.loanCalcColor,
          onChanged: (method) => setState(() => _method = method),
          tabs: [
            SegmentedTab(value: LoanInterestMethod.annuity, label: s.loan_calc_method_annuity),
            SegmentedTab(value: LoanInterestMethod.flat, label: s.loan_calc_method_flat),
          ],
        ),
        const SizedBox(height: Insets.lg),
        Text(
          s.loan_calc_affordability_title.toUpperCase(),
          style: AppType.label.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: Insets.sm),
        AppTextField(
          label: s.loan_calc_monthly_income,
          controller: _incomeCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: CupertinoIcons.money_dollar,
          inputFormatters: [ThousandSeparatorFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Insets.md),
        AppTextField(
          label: s.loan_calc_other_installments,
          controller: _otherInstallmentCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: CupertinoIcons.money_dollar,
          inputFormatters: [ThousandSeparatorFormatter()],
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

class _InstallmentResultCard extends StatelessWidget {
  final LoanCalcResult result;
  final NumberFormat fmt;
  final AppStrings s;

  const _InstallmentResultCard({required this.result, required this.fmt, required this.s});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: AppColors.loanCalcColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.loanCalcColor.withValues(alpha: 0.3)),
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
          _ResultRow(label: s.loan_calc_total_interest, value: fmt.format(result.totalInterest)),
          const SizedBox(height: Insets.sm),
          _ResultRow(label: s.loan_calc_total_payment, value: fmt.format(result.totalPayment)),
        ],
      ),
    );
  }
}

class _RateResultCard extends StatelessWidget {
  final LoanRateResult result;
  final NumberFormat fmt;
  final AppStrings s;

  const _RateResultCard({required this.result, required this.fmt, required this.s});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rate = result.annualRatePercent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: AppColors.loanCalcColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.loanCalcColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.loan_calc_estimated_rate.toUpperCase(),
            style: AppType.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Insets.xs),
          if (rate == null)
            Text(
              s.loan_calc_rate_not_found,
              style: AppType.body.copyWith(color: c.textSecondary),
            )
          else ...[
            Text(
              '${rate.toStringAsFixed(2)}% / tahun',
              style: AppType.display.copyWith(color: AppColors.loanCalcColor),
            ),
            const SizedBox(height: Insets.lg),
            _ResultRow(label: s.loan_calc_total_interest, value: fmt.format(result.totalInterest)),
            const SizedBox(height: Insets.sm),
            _ResultRow(label: s.loan_calc_total_payment, value: fmt.format(result.totalPayment)),
          ],
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: AppType.body.copyWith(color: c.textSecondary)),
        ),
        const SizedBox(width: Insets.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: AppType.body.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _KprResultCard extends StatelessWidget {
  final double propertyPrice;
  final double dpPercent;
  final double fixedRatePercent;
  final int fixedYears;
  final double floatingRatePercent;
  final int tenorYears;
  final LoanInterestMethod method;
  final double monthlyIncome;
  final double otherInstallments;
  final NumberFormat fmt;
  final AppStrings s;

  const _KprResultCard({
    required this.propertyPrice,
    required this.dpPercent,
    required this.fixedRatePercent,
    required this.fixedYears,
    required this.floatingRatePercent,
    required this.tenorYears,
    required this.method,
    required this.monthlyIncome,
    required this.otherInstallments,
    required this.fmt,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final costs = estimateKprCosts(propertyPrice: propertyPrice, downPaymentPercent: dpPercent);
    final staged = calculateKprStaged(
      principal: costs.loanPrincipal,
      fixedRatePercent: fixedRatePercent,
      fixedYears: fixedYears,
      floatingRatePercent: floatingRatePercent,
      totalTenorYears: tenorYears,
      method: method,
    );

    final hasIncome = monthlyIncome > 0;
    final affordability = hasIncome
        ? estimateKprAffordability(
            monthlyIncome: monthlyIncome,
            otherInstallments: otherInstallments,
            annualRatePercent: fixedRatePercent,
            tenorMonths: tenorYears * 12,
            method: method,
            downPaymentPercent: dpPercent,
          )
        : null;
    final incomeIsEnough =
        affordability != null && staged.fixedMonthlyInstallment <= affordability.maxMonthlyInstallment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Insets.lg),
          decoration: BoxDecoration(
            color: AppColors.loanCalcColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: AppColors.loanCalcColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.loan_calc_installment_fixed_period.toUpperCase(),
                style: AppType.label.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: Insets.xs),
              Text(
                fmt.format(staged.fixedMonthlyInstallment),
                style: AppType.display.copyWith(color: AppColors.loanCalcColor),
              ),
              if (staged.hasFloatingStage) ...[
                const SizedBox(height: Insets.lg),
                Text(
                  s.loan_calc_installment_floating_period.toUpperCase(),
                  style: AppType.label.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: Insets.xs),
                Text(
                  fmt.format(staged.floatingMonthlyInstallment),
                  style: AppType.title.copyWith(color: c.textPrimary),
                ),
              ],
              const SizedBox(height: Insets.lg),
              _ResultRow(label: s.loan_calc_down_payment_amount, value: fmt.format(costs.downPayment)),
              const SizedBox(height: Insets.sm),
              _ResultRow(label: s.loan_calc_principal, value: fmt.format(costs.loanPrincipal)),
            ],
          ),
        ),
        const SizedBox(height: Insets.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Insets.lg),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.loan_calc_costs_title.toUpperCase(),
                style: AppType.label.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: Insets.md),
              _ResultRow(label: s.loan_calc_cost_provisi, value: fmt.format(costs.provisiFee)),
              const SizedBox(height: Insets.sm),
              _ResultRow(label: s.loan_calc_cost_admin, value: fmt.format(costs.adminFee)),
              const SizedBox(height: Insets.sm),
              _ResultRow(label: s.loan_calc_cost_other, value: fmt.format(costs.otherFeesEstimate)),
              const SizedBox(height: Insets.sm),
              Divider(color: c.border),
              const SizedBox(height: Insets.sm),
              _ResultRow(
                label: s.loan_calc_cost_total,
                value: fmt.format(costs.totalUpfrontCost),
              ),
            ],
          ),
        ),
        if (hasIncome) ...[
          const SizedBox(height: Insets.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Insets.lg),
            decoration: BoxDecoration(
              color: (incomeIsEnough ? AppColors.income : AppColors.expense).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(
                color: (incomeIsEnough ? AppColors.income : AppColors.expense).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.loan_calc_affordability_title.toUpperCase(),
                  style: AppType.label.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: Insets.md),
                _ResultRow(
                  label: s.loan_calc_max_installment,
                  value: fmt.format(affordability!.maxMonthlyInstallment),
                ),
                const SizedBox(height: Insets.sm),
                _ResultRow(
                  label: s.loan_calc_max_property_price,
                  value: fmt.format(affordability.maxPropertyPrice),
                ),
                const SizedBox(height: Insets.md),
                Text(
                  incomeIsEnough ? s.loan_calc_income_enough : s.loan_calc_income_not_enough,
                  style: AppType.body.copyWith(
                    color: incomeIsEnough ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
