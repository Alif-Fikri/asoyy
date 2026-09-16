import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/calculator/domain/format_calculator_display.dart';

void main() {
  group('formatCalculatorDisplay', () {
    test('groups the integer part in thousands', () {
      expect(formatCalculatorDisplay('1234567'), '1,234,567');
    });

    test('leaves short numbers untouched', () {
      expect(formatCalculatorDisplay('42'), '42');
    });

    test('keeps the decimal part unformatted', () {
      expect(formatCalculatorDisplay('1234.5678'), '1,234.5678');
    });

    test('keeps a trailing decimal point while typing', () {
      expect(formatCalculatorDisplay('1234.'), '1,234.');
    });

    test('handles a negative number', () {
      expect(formatCalculatorDisplay('-1234567'), '-1,234,567');
    });

    test('an empty string stays empty', () {
      expect(formatCalculatorDisplay(''), '');
    });
  });

  group('formatCalculatorExpression', () {
    test('formats every numeric token but leaves operators alone', () {
      expect(formatCalculatorExpression('1234567 + 89'), '1,234,567 + 89');
    });

    test('formats a finished equation', () {
      expect(formatCalculatorExpression('1000 × 2000 ='), '1,000 × 2,000 =');
    });
  });

  group('rawIndexToFormattedIndex and formattedIndexToRawIndex round-trip', () {
    test('every raw index maps forward and back to itself', () {
      const raw = '1234567.89';
      for (var i = 0; i <= raw.length; i++) {
        final formattedIndex = rawIndexToFormattedIndex(raw, i);
        final roundTripped = formattedIndexToRawIndex(formatCalculatorDisplay(raw), formattedIndex);
        expect(roundTripped, i, reason: 'raw index $i round-tripped to $roundTripped');
      }
    });

    test('placing the cursor right after the first digit lands before the separator', () {
      expect(rawIndexToFormattedIndex('1234', 1), 1);
    });

    test('placing the cursor after the second digit lands after the separator', () {
      expect(rawIndexToFormattedIndex('1234', 2), 3);
    });

    test('tapping right before a separator maps back to the digit before it', () {
      expect(formattedIndexToRawIndex('1,234', 1), 1);
    });

    test('tapping right after a separator maps back to the digit after it', () {
      expect(formattedIndexToRawIndex('1,234', 2), 1);
    });
  });
}
