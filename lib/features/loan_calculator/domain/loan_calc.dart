enum LoanInterestMethod { annuity, flat }

class LoanCalcResult {
  final double monthlyInstallment;
  final double totalInterest;
  final double totalPayment;

  const LoanCalcResult({
    required this.monthlyInstallment,
    required this.totalInterest,
    required this.totalPayment,
  });
}

LoanCalcResult calculateLoan({
  required double principal,
  required double annualRatePercent,
  required int tenorMonths,
  required LoanInterestMethod method,
}) {
  if (principal <= 0 || tenorMonths <= 0) {
    return const LoanCalcResult(monthlyInstallment: 0, totalInterest: 0, totalPayment: 0);
  }

  final monthlyRate = annualRatePercent / 100 / 12;

  if (method == LoanInterestMethod.flat) {
    final monthlyInterest = principal * monthlyRate;
    final monthlyInstallment = principal / tenorMonths + monthlyInterest;
    final totalPayment = monthlyInstallment * tenorMonths;
    final totalInterest = totalPayment - principal;
    return LoanCalcResult(
      monthlyInstallment: monthlyInstallment,
      totalInterest: totalInterest,
      totalPayment: totalPayment,
    );
  }

  final monthlyInstallment = _annuityPayment(principal, monthlyRate, tenorMonths);
  final totalPayment = monthlyInstallment * tenorMonths;
  final totalInterest = totalPayment - principal;
  return LoanCalcResult(
    monthlyInstallment: monthlyInstallment,
    totalInterest: totalInterest,
    totalPayment: totalPayment,
  );
}

class LoanRateResult {
  final double? annualRatePercent;
  final double totalInterest;
  final double totalPayment;

  const LoanRateResult({
    required this.annualRatePercent,
    required this.totalInterest,
    required this.totalPayment,
  });
}

double _annuityPayment(double principal, double monthlyRate, int tenorMonths) {
  if (monthlyRate == 0) return principal / tenorMonths;
  final factor = 1 + monthlyRate;
  var powFactor = 1.0;
  for (var i = 0; i < tenorMonths; i++) {
    powFactor *= factor;
  }
  return principal * monthlyRate * powFactor / (powFactor - 1);
}

/// Solves for the annual interest rate given a known monthly installment,
/// since there is no closed-form inverse for the annuity formula.
LoanRateResult solveLoanRate({
  required double principal,
  required double monthlyInstallment,
  required int tenorMonths,
  required LoanInterestMethod method,
}) {
  if (principal <= 0 || tenorMonths <= 0 || monthlyInstallment <= 0) {
    return const LoanRateResult(annualRatePercent: null, totalInterest: 0, totalPayment: 0);
  }

  final totalPayment = monthlyInstallment * tenorMonths;
  final totalInterest = totalPayment - principal;

  if (method == LoanInterestMethod.flat) {
    final minInstallment = principal / tenorMonths;
    if (monthlyInstallment < minInstallment) {
      return LoanRateResult(annualRatePercent: null, totalInterest: totalInterest, totalPayment: totalPayment);
    }
    final monthlyInterest = monthlyInstallment - minInstallment;
    final monthlyRate = monthlyInterest / principal;
    return LoanRateResult(
      annualRatePercent: monthlyRate * 12 * 100,
      totalInterest: totalInterest,
      totalPayment: totalPayment,
    );
  }

  final minInstallment = principal / tenorMonths;
  if (monthlyInstallment <= minInstallment) {
    return LoanRateResult(annualRatePercent: null, totalInterest: totalInterest, totalPayment: totalPayment);
  }

  var low = 0.0;
  var high = 1.0; // monthly rate up to 100% — comfortably above any realistic loan
  for (var i = 0; i < 100; i++) {
    final mid = (low + high) / 2;
    final payment = _annuityPayment(principal, mid, tenorMonths);
    if (payment > monthlyInstallment) {
      high = mid;
    } else {
      low = mid;
    }
  }
  final monthlyRate = (low + high) / 2;
  return LoanRateResult(
    annualRatePercent: monthlyRate * 12 * 100,
    totalInterest: totalInterest,
    totalPayment: totalPayment,
  );
}
