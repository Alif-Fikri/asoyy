import 'package:asoyy/features/loan_calculator/domain/loan_calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateLoan - annuity', () {
    test('matches the standard annuity formula', () {
      // 100jt, 12%/tahun, 12 bulan -> cicilan ~8.884.879
      final r = calculateLoan(
        principal: 100000000,
        annualRatePercent: 12,
        tenorMonths: 12,
        method: LoanInterestMethod.annuity,
      );
      expect(r.monthlyInstallment, closeTo(8884878.87, 1));
      expect(r.totalPayment, closeTo(r.monthlyInstallment * 12, 0.01));
      expect(r.totalInterest, closeTo(r.totalPayment - 100000000, 0.01));
    });

    test('zero interest splits the principal evenly', () {
      final r = calculateLoan(
        principal: 12000000,
        annualRatePercent: 0,
        tenorMonths: 24,
        method: LoanInterestMethod.annuity,
      );
      expect(r.monthlyInstallment, closeTo(500000, 0.01));
      expect(r.totalInterest, closeTo(0, 0.01));
    });

    test('annuity is cheaper than flat for the same rate', () {
      const principal = 50000000.0;
      const rate = 10.0;
      const tenor = 36;
      final annuity = calculateLoan(
        principal: principal,
        annualRatePercent: rate,
        tenorMonths: tenor,
        method: LoanInterestMethod.annuity,
      );
      final flat = calculateLoan(
        principal: principal,
        annualRatePercent: rate,
        tenorMonths: tenor,
        method: LoanInterestMethod.flat,
      );
      expect(annuity.totalInterest, lessThan(flat.totalInterest));
    });

    test('long tenor stays finite (no overflow in the power loop)', () {
      final r = calculateLoan(
        principal: 1000000000,
        annualRatePercent: 12,
        tenorMonths: 360,
        method: LoanInterestMethod.annuity,
      );
      expect(r.monthlyInstallment.isFinite, isTrue);
      expect(r.monthlyInstallment, closeTo(10286125.72, 5));
    });
  });

  group('calculateLoan - flat', () {
    test('interest is charged on the full principal every month', () {
      final r = calculateLoan(
        principal: 120000000,
        annualRatePercent: 12,
        tenorMonths: 12,
        method: LoanInterestMethod.flat,
      );
      // pokok 10jt + bunga 1.2jt per bulan
      expect(r.monthlyInstallment, closeTo(11200000, 0.01));
      expect(r.totalInterest, closeTo(14400000, 0.01));
      expect(r.totalPayment, closeTo(134400000, 0.01));
    });
  });

  group('calculateLoan - guards', () {
    test('returns zeros for non-positive principal or tenor', () {
      for (final r in [
        calculateLoan(
          principal: 0,
          annualRatePercent: 10,
          tenorMonths: 12,
          method: LoanInterestMethod.annuity,
        ),
        calculateLoan(
          principal: -5,
          annualRatePercent: 10,
          tenorMonths: 12,
          method: LoanInterestMethod.flat,
        ),
        calculateLoan(
          principal: 1000,
          annualRatePercent: 10,
          tenorMonths: 0,
          method: LoanInterestMethod.annuity,
        ),
      ]) {
        expect(r.monthlyInstallment, 0);
        expect(r.totalInterest, 0);
        expect(r.totalPayment, 0);
      }
    });
  });

  group('solveLoanRate', () {
    test('annuity: recovers the rate used to build the installment', () {
      const principal = 250000000.0;
      const tenor = 60;
      const rate = 9.5;
      final forward = calculateLoan(
        principal: principal,
        annualRatePercent: rate,
        tenorMonths: tenor,
        method: LoanInterestMethod.annuity,
      );
      final back = solveLoanRate(
        principal: principal,
        monthlyInstallment: forward.monthlyInstallment,
        tenorMonths: tenor,
        method: LoanInterestMethod.annuity,
      );
      expect(back.annualRatePercent, isNotNull);
      expect(back.annualRatePercent!, closeTo(rate, 0.001));
    });

    test('flat: recovers the rate used to build the installment', () {
      const principal = 60000000.0;
      const tenor = 24;
      const rate = 7.0;
      final forward = calculateLoan(
        principal: principal,
        annualRatePercent: rate,
        tenorMonths: tenor,
        method: LoanInterestMethod.flat,
      );
      final back = solveLoanRate(
        principal: principal,
        monthlyInstallment: forward.monthlyInstallment,
        tenorMonths: tenor,
        method: LoanInterestMethod.flat,
      );
      expect(back.annualRatePercent!, closeTo(rate, 0.0001));
    });

    test('installment exactly equal to principal/tenor means 0% flat', () {
      final r = solveLoanRate(
        principal: 12000000,
        monthlyInstallment: 1000000,
        tenorMonths: 12,
        method: LoanInterestMethod.flat,
      );
      expect(r.annualRatePercent, closeTo(0, 1e-9));
    });

    test('installment below principal/tenor is unsolvable', () {
      for (final method in LoanInterestMethod.values) {
        final r = solveLoanRate(
          principal: 12000000,
          monthlyInstallment: 900000,
          tenorMonths: 12,
          method: method,
        );
        expect(r.annualRatePercent, isNull, reason: '$method');
        // totals are still reported so the UI can show the shortfall
        expect(r.totalPayment, closeTo(10800000, 0.01));
        expect(r.totalInterest, closeTo(-1200000, 0.01));
      }
    });

    test('annuity at exactly principal/tenor is unsolvable (rate would be 0)', () {
      final r = solveLoanRate(
        principal: 12000000,
        monthlyInstallment: 1000000,
        tenorMonths: 12,
        method: LoanInterestMethod.annuity,
      );
      expect(r.annualRatePercent, isNull);
    });

    test('returns nulls for invalid input', () {
      final r = solveLoanRate(
        principal: 0,
        monthlyInstallment: 100,
        tenorMonths: 12,
        method: LoanInterestMethod.annuity,
      );
      expect(r.annualRatePercent, isNull);
      expect(r.totalPayment, 0);
    });
  });
}
