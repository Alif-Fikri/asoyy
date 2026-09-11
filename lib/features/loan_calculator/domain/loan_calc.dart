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

  double monthlyInstallment;
  if (monthlyRate == 0) {
    monthlyInstallment = principal / tenorMonths;
  } else {
    final factor = (1 + monthlyRate);
    var powFactor = 1.0;
    for (var i = 0; i < tenorMonths; i++) {
      powFactor *= factor;
    }
    monthlyInstallment = principal * monthlyRate * powFactor / (powFactor - 1);
  }
  final totalPayment = monthlyInstallment * tenorMonths;
  final totalInterest = totalPayment - principal;
  return LoanCalcResult(
    monthlyInstallment: monthlyInstallment,
    totalInterest: totalInterest,
    totalPayment: totalPayment,
  );
}
