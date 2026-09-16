import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/loan_calculator/domain/kpr_calc.dart';
import 'package:asoyy/features/loan_calculator/domain/loan_calc.dart';

void main() {
  group('estimateKprCosts', () {
    test('splits property price into down payment and loan principal', () {
      final result = estimateKprCosts(propertyPrice: 500000000, downPaymentPercent: 20);
      expect(result.downPayment, 100000000);
      expect(result.loanPrincipal, 400000000);
    });

    test('estimates provisi, admin, and other fees off the loan principal', () {
      final result = estimateKprCosts(
        propertyPrice: 500000000,
        downPaymentPercent: 20,
        provisiPercent: 1,
        adminFee: 500000,
        otherFeesPercent: 7,
      );
      expect(result.provisiFee, 4000000);
      expect(result.adminFee, 500000);
      expect(result.otherFeesEstimate, 28000000);
      expect(result.totalUpfrontCost, 100000000 + 4000000 + 500000 + 28000000);
    });

    test('a non-positive property price yields all zeros', () {
      final result = estimateKprCosts(propertyPrice: 0, downPaymentPercent: 20);
      expect(result.totalUpfrontCost, 0);
    });
  });

  group('maxPrincipalForInstallment', () {
    test('an installment large enough to invert the annuity formula', () {
      const principal = 300000000.0;
      const monthlyRate = 0.08 / 12;
      const tenorMonths = 180;
      final installment = annuityPayment(principal, monthlyRate, tenorMonths);

      final recovered = maxPrincipalForInstallment(
        installment: installment,
        monthlyRate: monthlyRate,
        tenorMonths: tenorMonths,
        method: LoanInterestMethod.annuity,
      );

      expect(recovered, closeTo(principal, 1));
    });

    test('flat method inverts the same way', () {
      const principal = 120000000.0;
      const monthlyRate = 0.06 / 12;
      const tenorMonths = 60;
      final installment = principal / tenorMonths + principal * monthlyRate;

      final recovered = maxPrincipalForInstallment(
        installment: installment,
        monthlyRate: monthlyRate,
        tenorMonths: tenorMonths,
        method: LoanInterestMethod.flat,
      );

      expect(recovered, closeTo(principal, 1));
    });
  });

  group('estimateKprAffordability', () {
    test('caps the installment at 40% of income minus other debts', () {
      final result = estimateKprAffordability(
        monthlyIncome: 10000000,
        otherInstallments: 1000000,
        annualRatePercent: 8,
        tenorMonths: 180,
        method: LoanInterestMethod.annuity,
        downPaymentPercent: 20,
      );
      expect(result.maxMonthlyInstallment, 3000000);
      expect(result.maxLoanPrincipal, greaterThan(0));
      expect(result.maxPropertyPrice, closeTo(result.maxLoanPrincipal / 0.8, 1));
    });

    test('other debts eating the whole ratio leaves nothing affordable', () {
      final result = estimateKprAffordability(
        monthlyIncome: 5000000,
        otherInstallments: 3000000,
        annualRatePercent: 8,
        tenorMonths: 180,
        method: LoanInterestMethod.annuity,
        downPaymentPercent: 20,
      );
      expect(result.maxMonthlyInstallment, 0);
      expect(result.maxLoanPrincipal, 0);
      expect(result.maxPropertyPrice, 0);
    });
  });

  group('calculateKprStaged', () {
    test('no fixed period means the whole tenor is floating', () {
      final result = calculateKprStaged(
        principal: 300000000,
        fixedRatePercent: 6,
        fixedYears: 0,
        floatingRatePercent: 11,
        totalTenorYears: 15,
        method: LoanInterestMethod.annuity,
      );
      expect(result.fixedMonths, 0);
      expect(result.floatingMonths, 180);
    });

    test('a fixed period spanning the whole tenor has no floating stage', () {
      final result = calculateKprStaged(
        principal: 300000000,
        fixedRatePercent: 6,
        fixedYears: 20,
        floatingRatePercent: 11,
        totalTenorYears: 15,
        method: LoanInterestMethod.annuity,
      );
      expect(result.fixedMonths, 180);
      expect(result.hasFloatingStage, isFalse);
      expect(result.floatingMonthlyInstallment, result.fixedMonthlyInstallment);
    });

    test('the floating installment jumps once the promo rate ends', () {
      final result = calculateKprStaged(
        principal: 300000000,
        fixedRatePercent: 5.25,
        fixedYears: 3,
        floatingRatePercent: 11,
        totalTenorYears: 15,
        method: LoanInterestMethod.annuity,
      );
      expect(result.fixedMonths, 36);
      expect(result.floatingMonths, 144);
      expect(result.floatingMonthlyInstallment, greaterThan(result.fixedMonthlyInstallment));
      expect(result.remainingPrincipalAtTransition, lessThan(300000000));
      expect(result.remainingPrincipalAtTransition, greaterThan(0));
    });

    test('flat method reduces the principal linearly before the floating stage', () {
      final result = calculateKprStaged(
        principal: 120000000,
        fixedRatePercent: 6,
        fixedYears: 2,
        floatingRatePercent: 10,
        totalTenorYears: 10,
        method: LoanInterestMethod.flat,
      );
      expect(result.remainingPrincipalAtTransition, closeTo(120000000 - 120000000 / 120 * 24, 1));
    });
  });
}
