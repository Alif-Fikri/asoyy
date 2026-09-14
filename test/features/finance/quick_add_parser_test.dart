import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/utils/quick_add_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('amount parsing', () {
    test('plain number', () {
      final r = parseQuickAddText('kopi 25000')!;
      expect(r.amount, 25000);
    });

    test('thousand separators are stripped', () {
      expect(parseQuickAddText('belanja 1.250.000')!.amount, 1250000);
      expect(parseQuickAddText('belanja 1,250,000')!.amount, 1250000);
    });

    test('ribu/rb/k suffixes', () {
      for (final input in ['kopi 25ribu', 'kopi 25 rb', 'kopi 25k']) {
        expect(parseQuickAddText(input)!.amount, 25000, reason: input);
      }
    });

    test('juta/jt/m suffixes', () {
      for (final input in ['gaji 5juta', 'gaji 5 jt', 'gaji 5m']) {
        expect(parseQuickAddText(input)!.amount, 5000000, reason: input);
      }
    });

    test('suffixed number wins over a bare number elsewhere in the text', () {
      final r = parseQuickAddText('makan siang 2 porsi 50rb')!;
      expect(r.amount, 50000);
    });

    test('returns null when there is no number', () {
      expect(parseQuickAddText('kopi susu'), isNull);
      expect(parseQuickAddText(''), isNull);
      expect(parseQuickAddText('   '), isNull);
    });

    test('returns null for a zero amount', () {
      expect(parseQuickAddText('kopi 0'), isNull);
    });
  });

  group('category & type', () {
    test('expense keywords map to their category', () {
      expect(parseQuickAddText('kopi 20rb')!.category, 'Makan');
      expect(parseQuickAddText('bensin 50rb')!.category, 'Transport');
      expect(parseQuickAddText('bayar listrik 300rb')!.category, 'Tagihan');
      expect(parseQuickAddText('nonton bioskop 60rb')!.category, 'Hiburan');
    });

    test('expense is the default type', () {
      final r = parseQuickAddText('kopi 20rb')!;
      expect(r.type, TransactionType.expense);
    });

    test('income keywords flip the type and category', () {
      final r = parseQuickAddText('gaji bulanan 8jt')!;
      expect(r.type, TransactionType.income);
      expect(r.category, 'Gaji');
    });

    test('income signal words flip the type without a category match', () {
      final r = parseQuickAddText('dapat uang 500rb')!;
      expect(r.type, TransactionType.income);
      expect(r.category, 'Lainnya');
    });

    test('unknown words fall back to Lainnya', () {
      final r = parseQuickAddText('xyz 15rb')!;
      expect(r.category, 'Lainnya');
      expect(r.type, TransactionType.expense);
    });
  });

  group('title', () {
    test('is the remaining text, capitalized', () {
      expect(parseQuickAddText('kopi susu 25rb')!.title, 'Kopi susu');
    });

    test('falls back to the category when only a number is given', () {
      final r = parseQuickAddText('25rb')!;
      expect(r.title, 'Lainnya');
      expect(r.amount, 25000);
    });

    test('collapses the whitespace left behind by the amount', () {
      expect(parseQuickAddText('beli  kopi   25rb  pagi')!.title,
          'Beli kopi pagi');
    });
  });
}
