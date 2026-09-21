import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/utils/title_suggestions.dart';

TransactionEntity _tx(String title) => TransactionEntity(
      id: title,
      title: title,
      amount: 1000,
      type: TransactionType.expense,
      category: 'Food',
      date: DateTime(2026, 1, 1),
    );

void main() {
  group('distinctTitles', () {
    test('deduplicates repeated titles', () {
      final titles = distinctTitles([_tx('Kopi'), _tx('Kopi'), _tx('Teh')]);
      expect(titles, containsAll(['Kopi', 'Teh']));
      expect(titles.length, 2);
    });

    test('orders by frequency, most used first', () {
      final titles = distinctTitles([
        _tx('Kopi'),
        _tx('Teh'),
        _tx('Kopi'),
        _tx('Kopi'),
      ]);
      expect(titles.first, 'Kopi');
    });

    test('ignores blank titles', () {
      final titles = distinctTitles([_tx(''), _tx('  '), _tx('Kopi')]);
      expect(titles, ['Kopi']);
    });

    test('respects the limit', () {
      final txs = List.generate(10, (i) => _tx('Item $i'));
      expect(distinctTitles(txs, limit: 3).length, 3);
    });

    test('an empty list yields no suggestions', () {
      expect(distinctTitles(const []), isEmpty);
    });
  });
}
