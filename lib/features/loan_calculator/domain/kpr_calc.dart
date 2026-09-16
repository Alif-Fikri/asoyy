import 'loan_calc.dart';

class KprCostBreakdown {
  final double downPayment;
  final double loanPrincipal;
  final double provisiFee;
  final double adminFee;
  final double otherFeesEstimate;
  final double totalUpfrontCost;

  const KprCostBreakdown({
    required this.downPayment,
    required this.loanPrincipal,
    required this.provisiFee,
    required this.adminFee,
    required this.otherFeesEstimate,
    required this.totalUpfrontCost,
  });
}

KprCostBreakdown estimateKprCosts({
  required double propertyPrice,
  required double downPaymentPercent,
  double provisiPercent = 1,
  double adminFee = 500000,
  double otherFeesPercent = 7,
}) {
  if (propertyPrice <= 0) {
    return const KprCostBreakdown(
      downPayment: 0,
      loanPrincipal: 0,
      provisiFee: 0,
      adminFee: 0,
      otherFeesEstimate: 0,
      totalUpfrontCost: 0,
    );
  }
  final downPayment = propertyPrice * downPaymentPercent / 100;
  final loanPrincipal = propertyPrice - downPayment;
  final provisiFee = loanPrincipal * provisiPercent / 100;
  final otherFeesEstimate = loanPrincipal * otherFeesPercent / 100;
  final totalUpfrontCost = downPayment + provisiFee + adminFee + otherFeesEstimate;
  return KprCostBreakdown(
    downPayment: downPayment,
    loanPrincipal: loanPrincipal,
    provisiFee: provisiFee,
    adminFee: adminFee,
    otherFeesEstimate: otherFeesEstimate,
    totalUpfrontCost: totalUpfrontCost,
  );
}

double maxPrincipalForInstallment({
  required double installment,
  required double monthlyRate,
  required int tenorMonths,
  required LoanInterestMethod method,
}) {
  if (installment <= 0 || tenorMonths <= 0) return 0;

  if (method == LoanInterestMethod.flat) {
    final denom = 1 / tenorMonths + monthlyRate;
    return denom <= 0 ? 0 : installment / denom;
  }

  if (monthlyRate == 0) return installment * tenorMonths;

  var factor = 1.0;
  for (var i = 0; i < tenorMonths; i++) {
    factor *= 1 + monthlyRate;
  }
  final denom = monthlyRate * factor / (factor - 1);
  return denom <= 0 ? 0 : installment / denom;
}

class KprAffordabilityResult {
  final double maxMonthlyInstallment;
  final double maxLoanPrincipal;
  final double maxPropertyPrice;

  const KprAffordabilityResult({
    required this.maxMonthlyInstallment,
    required this.maxLoanPrincipal,
    required this.maxPropertyPrice,
  });
}

KprAffordabilityResult estimateKprAffordability({
  required double monthlyIncome,
  required double otherInstallments,
  required double annualRatePercent,
  required int tenorMonths,
  required LoanInterestMethod method,
  required double downPaymentPercent,
  double maxInstallmentRatio = 0.4,
}) {
  final maxInstallment = monthlyIncome * maxInstallmentRatio - otherInstallments;
  if (maxInstallment <= 0 || tenorMonths <= 0) {
    return const KprAffordabilityResult(
      maxMonthlyInstallment: 0,
      maxLoanPrincipal: 0,
      maxPropertyPrice: 0,
    );
  }

  final monthlyRate = annualRatePercent / 100 / 12;
  final maxPrincipal = maxPrincipalForInstallment(
    installment: maxInstallment,
    monthlyRate: monthlyRate,
    tenorMonths: tenorMonths,
    method: method,
  );

  final dpFraction = 1 - downPaymentPercent / 100;
  final maxPropertyPrice = dpFraction > 0 ? maxPrincipal / dpFraction : maxPrincipal;

  return KprAffordabilityResult(
    maxMonthlyInstallment: maxInstallment,
    maxLoanPrincipal: maxPrincipal,
    maxPropertyPrice: maxPropertyPrice,
  );
}

class KprStagedResult {
  final double fixedMonthlyInstallment;
  final double floatingMonthlyInstallment;
  final double remainingPrincipalAtTransition;
  final int fixedMonths;
  final int floatingMonths;

  const KprStagedResult({
    required this.fixedMonthlyInstallment,
    required this.floatingMonthlyInstallment,
    required this.remainingPrincipalAtTransition,
    required this.fixedMonths,
    required this.floatingMonths,
  });

  bool get hasFloatingStage => floatingMonths > 0;
}

KprStagedResult calculateKprStaged({
  required double principal,
  required double fixedRatePercent,
  required int fixedYears,
  required double floatingRatePercent,
  required int totalTenorYears,
  required LoanInterestMethod method,
}) {
  final totalMonths = totalTenorYears * 12;
  if (totalMonths <= 0 || principal <= 0) {
    return const KprStagedResult(
      fixedMonthlyInstallment: 0,
      floatingMonthlyInstallment: 0,
      remainingPrincipalAtTransition: 0,
      fixedMonths: 0,
      floatingMonths: 0,
    );
  }

  final fixedMonths = (fixedYears * 12).clamp(0, totalMonths);
  final floatingMonths = totalMonths - fixedMonths;

  final fixedMonthlyRate = fixedRatePercent / 100 / 12;
  final fixedInstallment = method == LoanInterestMethod.flat
      ? principal / totalMonths + principal * fixedMonthlyRate
      : annuityPayment(principal, fixedMonthlyRate, totalMonths);

  if (floatingMonths <= 0) {
    return KprStagedResult(
      fixedMonthlyInstallment: fixedInstallment,
      floatingMonthlyInstallment: fixedInstallment,
      remainingPrincipalAtTransition: 0,
      fixedMonths: fixedMonths,
      floatingMonths: 0,
    );
  }

  var remaining = principal;
  if (method == LoanInterestMethod.flat) {
    remaining = principal - principal / totalMonths * fixedMonths;
  } else {
    for (var i = 0; i < fixedMonths; i++) {
      final interest = remaining * fixedMonthlyRate;
      remaining -= fixedInstallment - interest;
    }
  }
  if (remaining < 0) remaining = 0;

  final floatingMonthlyRate = floatingRatePercent / 100 / 12;
  final floatingInstallment = method == LoanInterestMethod.flat
      ? remaining / floatingMonths + remaining * floatingMonthlyRate
      : annuityPayment(remaining, floatingMonthlyRate, floatingMonths);

  return KprStagedResult(
    fixedMonthlyInstallment: fixedInstallment,
    floatingMonthlyInstallment: floatingInstallment,
    remainingPrincipalAtTransition: remaining,
    fixedMonths: fixedMonths,
    floatingMonths: floatingMonths,
  );
}
