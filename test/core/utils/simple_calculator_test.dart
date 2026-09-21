import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/core/utils/simple_calculator.dart';

void main() {
  group('evaluateExpression', () {
    test('a plain number', () {
      expect(evaluateExpression('1000'), 1000);
    });

    test('addition and multiplication respect precedence', () {
      expect(evaluateExpression('1000 + 2500 * 3'), 8500);
    });

    test('parentheses override precedence', () {
      expect(evaluateExpression('(1000 + 2500) * 3'), 10500);
    });

    test('division', () {
      expect(evaluateExpression('9000 / 3'), 3000);
    });

    test('division by zero is invalid', () {
      expect(evaluateExpression('1 / 0'), isNull);
    });

    test('unary minus', () {
      expect(evaluateExpression('-5 + 10'), 5);
    });

    test('decimal numbers', () {
      expect(evaluateExpression('2.5 * 4'), 10);
    });

    test('a comma decimal separator also works', () {
      expect(evaluateExpression('2,5 * 4'), 10);
    });

    test('blank input is invalid', () {
      expect(evaluateExpression(''), isNull);
      expect(evaluateExpression('   '), isNull);
    });

    test('garbage input is invalid', () {
      expect(evaluateExpression('abc'), isNull);
      expect(evaluateExpression('1 + '), isNull);
      expect(evaluateExpression('1 2'), isNull);
    });

    test('unbalanced parentheses are invalid', () {
      expect(evaluateExpression('(1 + 2'), isNull);
      expect(evaluateExpression('1 + 2)'), isNull);
    });
  });
}
