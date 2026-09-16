import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/utils/finance_csv_import.dart';

void main() {
  group('detectDelimiter', () {
    test('picks comma for a comma-separated header', () {
      expect(detectDelimiter('date,amount,description'), ',');
    });

    test('picks semicolon for a semicolon-separated header', () {
      expect(detectDelimiter('Tanggal;Nominal;Keterangan'), ';');
    });

    test('picks tab for a tab-separated header', () {
      expect(detectDelimiter('date\tamount\tdescription'), '\t');
    });
  });

  group('splitDelimitedLine', () {
    test('splits a plain line', () {
      expect(splitDelimitedLine('a,b,c', ','), ['a', 'b', 'c']);
    });

    test('keeps a comma inside quotes together', () {
      expect(splitDelimitedLine('a,"b, c",d', ','), ['a', 'b, c', 'd']);
    });

    test('unescapes doubled quotes', () {
      expect(splitDelimitedLine('a,"say ""hi""",c', ','), ['a', 'say "hi"', 'c']);
    });
  });

  group('parseDelimitedText', () {
    test('splits the header from the data rows', () {
      final csv = parseDelimitedText('date,amount\n2026-01-01,1000\n2026-01-02,2000');
      expect(csv.headers, ['date', 'amount']);
      expect(csv.rows, [
        ['2026-01-01', '1000'],
        ['2026-01-02', '2000'],
      ]);
    });

    test('drops blank lines', () {
      final csv = parseDelimitedText('date,amount\n\n2026-01-01,1000\n\n');
      expect(csv.rows.length, 1);
    });

    test('an empty document yields no headers and no rows', () {
      final csv = parseDelimitedText('');
      expect(csv.headers, isEmpty);
      expect(csv.rows, isEmpty);
    });
  });

  group('detectColumnMapping', () {
    test('recognizes an Indonesian bank export layout', () {
      final mapping = detectColumnMapping(['Tanggal', 'Keterangan', 'Debit', 'Kredit']);
      expect(mapping.dateColumn, 0);
      expect(mapping.descriptionColumn, 1);
      expect(mapping.debitColumn, 2);
      expect(mapping.creditColumn, 3);
      expect(mapping.isUsable, isTrue);
    });

    test('recognizes an English single-amount layout', () {
      final mapping = detectColumnMapping(['Date', 'Description', 'Amount']);
      expect(mapping.dateColumn, 0);
      expect(mapping.descriptionColumn, 1);
      expect(mapping.amountColumn, 2);
      expect(mapping.isUsable, isTrue);
    });

    test('matches a header that only contains the synonym as a substring', () {
      final mapping = detectColumnMapping(['Transaction Date', 'Merchant Name']);
      expect(mapping.dateColumn, 0);
      expect(mapping.descriptionColumn, 1);
    });

    test('is unusable when neither a date nor an amount column is found', () {
      final mapping = detectColumnMapping(['foo', 'bar']);
      expect(mapping.isUsable, isFalse);
    });
  });

  group('parseFlexibleDate', () {
    test('parses ISO format', () {
      expect(parseFlexibleDate('2026-03-05'), DateTime(2026, 3, 5));
    });

    test('parses dd/mm/yyyy, the Indonesian convention, when both parts are ambiguous', () {
      expect(parseFlexibleDate('05/03/2026'), DateTime(2026, 3, 5));
    });

    test('disambiguates using the part that must be a month', () {
      expect(parseFlexibleDate('13/03/2026'), DateTime(2026, 3, 13));
      expect(parseFlexibleDate('03/13/2026'), DateTime(2026, 3, 13));
    });

    test('accepts a two-digit year', () {
      expect(parseFlexibleDate('05-03-26'), DateTime(2026, 3, 5));
    });

    test('rejects an impossible date', () {
      expect(parseFlexibleDate('40/13/2026'), isNull);
    });

    test('rejects garbage', () {
      expect(parseFlexibleDate('not a date'), isNull);
    });

    test('rejects an empty string', () {
      expect(parseFlexibleDate(''), isNull);
    });
  });

  group('parseFlexibleAmount', () {
    test('parses a plain integer', () {
      expect(parseFlexibleAmount('50000'), 50000);
    });

    test('parses Indonesian-style thousands with a dot', () {
      expect(parseFlexibleAmount('1.234.567'), 1234567);
    });

    test('parses a decimal with a comma', () {
      expect(parseFlexibleAmount('1234,50'), 1234.50);
    });

    test('parses thousands-and-decimal together (dot thousands, comma decimal)', () {
      expect(parseFlexibleAmount('1.234.567,89'), closeTo(1234567.89, 0.001));
    });

    test('parses thousands-and-decimal together (comma thousands, dot decimal)', () {
      expect(parseFlexibleAmount('1,234,567.89'), closeTo(1234567.89, 0.001));
    });

    test('keeps a negative sign', () {
      expect(parseFlexibleAmount('-50000'), -50000);
    });

    test('strips a currency prefix', () {
      expect(parseFlexibleAmount('Rp 50.000'), 50000);
    });

    test('an empty string is not an amount', () {
      expect(parseFlexibleAmount(''), isNull);
    });

    test('text with no digits is not an amount', () {
      expect(parseFlexibleAmount('n/a'), isNull);
    });
  });

  group('parseImportRow', () {
    test('reads a debit/credit layout as expense or income', () {
      const mapping = ImportColumnMapping(
        dateColumn: 0,
        descriptionColumn: 1,
        debitColumn: 2,
        creditColumn: 3,
      );
      final expenseRow = parseImportRow(['2026-01-01', 'Kopi', '25000', ''], mapping);
      expect(expenseRow.type, TransactionType.expense);
      expect(expenseRow.amount, 25000);

      final incomeRow = parseImportRow(['2026-01-02', 'Gaji', '', '5000000'], mapping);
      expect(incomeRow.type, TransactionType.income);
      expect(incomeRow.amount, 5000000);
    });

    test('reads a signed single-amount layout', () {
      const mapping = ImportColumnMapping(dateColumn: 0, descriptionColumn: 1, amountColumn: 2);
      final row = parseImportRow(['2026-01-01', 'Kopi', '-25000'], mapping);
      expect(row.type, TransactionType.expense);
      expect(row.amount, 25000);
    });

    test('a row missing its date is invalid', () {
      const mapping = ImportColumnMapping(dateColumn: 0, amountColumn: 1);
      final row = parseImportRow(['not a date', '1000'], mapping);
      expect(row.isValid, isFalse);
    });

    test('a zero amount is invalid', () {
      const mapping = ImportColumnMapping(dateColumn: 0, amountColumn: 1);
      final row = parseImportRow(['2026-01-01', '0'], mapping);
      expect(row.isValid, isFalse);
    });

    test('a row shorter than the mapped columns does not crash', () {
      const mapping = ImportColumnMapping(dateColumn: 0, amountColumn: 5);
      final row = parseImportRow(['2026-01-01'], mapping);
      expect(row.isValid, isFalse);
    });
  });

  group('isDuplicateTransaction', () {
    final existing = TransactionEntity(
      id: 'a',
      title: 'Kopi',
      amount: 25000,
      type: TransactionType.expense,
      category: 'Makan',
      date: DateTime(2026, 1, 1),
    );

    test('flags a row matching an existing transaction on date, amount and type', () {
      final row = ImportedRow(
        date: DateTime(2026, 1, 1),
        amount: 25000,
        type: TransactionType.expense,
        description: 'Anything',
      );
      expect(isDuplicateTransaction(row, [existing]), isTrue);
    });

    test('does not flag a different amount', () {
      final row = ImportedRow(
        date: DateTime(2026, 1, 1),
        amount: 25001,
        type: TransactionType.expense,
        description: '',
      );
      expect(isDuplicateTransaction(row, [existing]), isFalse);
    });

    test('does not flag a different type on the same day and amount', () {
      final row = ImportedRow(
        date: DateTime(2026, 1, 1),
        amount: 25000,
        type: TransactionType.income,
        description: '',
      );
      expect(isDuplicateTransaction(row, [existing]), isFalse);
    });
  });

  group('buildImportedTransactions', () {
    test('builds transactions from valid rows and skips invalid ones', () {
      final rows = [
        ImportedRow(date: DateTime(2026, 1, 1), amount: 25000, type: TransactionType.expense, description: 'Kopi'),
        const ImportedRow(date: null, amount: null, type: null, description: ''),
      ];
      final result = buildImportedTransactions(
        rows: rows,
        accountId: 'acc1',
        defaultExpenseCategory: 'Lainnya',
        defaultIncomeCategory: 'Lainnya',
        existing: const [],
        generateId: () => 'new-id',
      );
      expect(result.length, 1);
      expect(result.first.title, 'Kopi');
      expect(result.first.accountId, 'acc1');
    });

    test('skips a row that duplicates one already imported earlier in the same batch', () {
      final rows = [
        ImportedRow(date: DateTime(2026, 1, 1), amount: 25000, type: TransactionType.expense, description: 'Kopi'),
        ImportedRow(date: DateTime(2026, 1, 1), amount: 25000, type: TransactionType.expense, description: 'Kopi lagi'),
      ];
      final result = buildImportedTransactions(
        rows: rows,
        accountId: 'acc1',
        defaultExpenseCategory: 'Lainnya',
        defaultIncomeCategory: 'Lainnya',
        existing: const [],
        generateId: () => 'new-id',
      );
      expect(result.length, 1);
    });

    test('falls back to the category name when the description is blank', () {
      final rows = [
        ImportedRow(date: DateTime(2026, 1, 1), amount: 25000, type: TransactionType.expense, description: '  '),
      ];
      final result = buildImportedTransactions(
        rows: rows,
        accountId: null,
        defaultExpenseCategory: 'Lainnya',
        defaultIncomeCategory: 'Lainnya',
        existing: const [],
        generateId: () => 'new-id',
      );
      expect(result.single.title, 'Lainnya');
      expect(result.single.accountId, isNull);
    });
  });
}
