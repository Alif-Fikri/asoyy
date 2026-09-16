import '../entities/transaction_entity.dart';

class ParsedCsv {
  final List<String> headers;
  final List<List<String>> rows;

  const ParsedCsv({required this.headers, required this.rows});
}

String detectDelimiter(String content) {
  final firstLine = content
      .split(RegExp(r'\r\n|\r|\n'))
      .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  final commaCount = ','.allMatches(firstLine).length;
  final semicolonCount = ';'.allMatches(firstLine).length;
  final tabCount = '\t'.allMatches(firstLine).length;
  if (semicolonCount > commaCount && semicolonCount > tabCount) return ';';
  if (tabCount > commaCount && tabCount > semicolonCount) return '\t';
  return ',';
}

List<String> splitDelimitedLine(String line, String delimiter) {
  final fields = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  var i = 0;
  while (i < line.length) {
    final ch = line[i];
    if (ch == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buffer.write('"');
        i += 2;
        continue;
      }
      inQuotes = !inQuotes;
    } else if (ch == delimiter && !inQuotes) {
      fields.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(ch);
    }
    i++;
  }
  fields.add(buffer.toString().trim());
  return fields;
}

ParsedCsv parseDelimitedText(String content) {
  final delimiter = detectDelimiter(content);
  final lines = content
      .split(RegExp(r'\r\n|\r|\n'))
      .where((l) => l.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) return const ParsedCsv(headers: [], rows: []);

  final parsedLines =
      lines.map((l) => splitDelimitedLine(l, delimiter)).toList();
  return ParsedCsv(
    headers: parsedLines.first,
    rows: parsedLines.skip(1).toList(),
  );
}

const dateHeaderSynonyms = [
  'tanggal', 'tgl', 'date', 'waktu', 'waktu transaksi', 'transaction date',
];
const descriptionHeaderSynonyms = [
  'keterangan', 'uraian', 'description', 'remark', 'catatan',
  'nama transaksi', 'merchant', 'jenis transaksi',
];
const amountHeaderSynonyms = ['nominal', 'jumlah', 'amount', 'value'];
const debitHeaderSynonyms = [
  'debit', 'debet', 'keluar', 'pengeluaran', 'withdrawal',
];
const creditHeaderSynonyms = [
  'kredit', 'credit', 'masuk', 'pemasukan', 'deposit',
];

int? findHeaderColumn(List<String> headers, List<String> synonyms) {
  final normalized = headers.map((h) => h.trim().toLowerCase()).toList();
  for (final syn in synonyms) {
    final idx = normalized.indexOf(syn);
    if (idx != -1) return idx;
  }
  for (var i = 0; i < normalized.length; i++) {
    for (final syn in synonyms) {
      if (normalized[i].contains(syn)) return i;
    }
  }
  return null;
}

class ImportColumnMapping {
  final int? dateColumn;
  final int? amountColumn;
  final int? debitColumn;
  final int? creditColumn;
  final int? descriptionColumn;

  const ImportColumnMapping({
    this.dateColumn,
    this.amountColumn,
    this.debitColumn,
    this.creditColumn,
    this.descriptionColumn,
  });

  bool get isUsable =>
      dateColumn != null && (amountColumn != null || debitColumn != null || creditColumn != null);

  ImportColumnMapping copyWith({
    int? dateColumn,
    int? amountColumn,
    int? debitColumn,
    int? creditColumn,
    int? descriptionColumn,
  }) =>
      ImportColumnMapping(
        dateColumn: dateColumn ?? this.dateColumn,
        amountColumn: amountColumn ?? this.amountColumn,
        debitColumn: debitColumn ?? this.debitColumn,
        creditColumn: creditColumn ?? this.creditColumn,
        descriptionColumn: descriptionColumn ?? this.descriptionColumn,
      );
}

ImportColumnMapping detectColumnMapping(List<String> headers) => ImportColumnMapping(
      dateColumn: findHeaderColumn(headers, dateHeaderSynonyms),
      amountColumn: findHeaderColumn(headers, amountHeaderSynonyms),
      debitColumn: findHeaderColumn(headers, debitHeaderSynonyms),
      creditColumn: findHeaderColumn(headers, creditHeaderSynonyms),
      descriptionColumn: findHeaderColumn(headers, descriptionHeaderSynonyms),
    );

DateTime? parseFlexibleDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;

  final isoMatch = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(s);
  if (isoMatch != null) {
    final month = int.parse(isoMatch.group(2)!);
    final day = int.parse(isoMatch.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(int.parse(isoMatch.group(1)!), month, day);
  }

  final slashMatch = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(s);
  if (slashMatch != null) {
    var year = int.parse(slashMatch.group(3)!);
    if (year < 100) year += 2000;
    final first = int.parse(slashMatch.group(1)!);
    final second = int.parse(slashMatch.group(2)!);

    int day;
    int month;
    if (first > 12) {
      day = first;
      month = second;
    } else if (second > 12) {
      day = second;
      month = first;
    } else {
      day = first;
      month = second;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  return null;
}

double? parseFlexibleAmount(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  s = s.replaceAll(RegExp(r'[^\d,.\-]'), '');
  if (s.isEmpty) return null;

  final negative = s.startsWith('-');
  s = s.replaceAll('-', '');
  if (s.isEmpty) return null;

  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');

  if (lastComma != -1 && lastDot != -1) {
    if (lastComma > lastDot) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else if (lastComma != -1) {
    final decimals = s.length - lastComma - 1;
    s = decimals <= 2 ? s.replaceAll(',', '.') : s.replaceAll(',', '');
  } else if (lastDot != -1) {
    final decimals = s.length - lastDot - 1;
    if (decimals != 2) s = s.replaceAll('.', '');
  }

  final value = double.tryParse(s);
  if (value == null) return null;
  return negative ? -value : value;
}

class ImportedRow {
  final DateTime? date;
  final double? amount;
  final TransactionType? type;
  final String description;

  const ImportedRow({
    required this.date,
    required this.amount,
    required this.type,
    required this.description,
  });

  bool get isValid => date != null && amount != null && amount != 0 && type != null;
}

ImportedRow parseImportRow(List<String> row, ImportColumnMapping mapping) {
  DateTime? date;
  final dateColumn = mapping.dateColumn;
  if (dateColumn != null && dateColumn < row.length) {
    date = parseFlexibleDate(row[dateColumn]);
  }

  double? amount;
  TransactionType? type;

  final debitColumn = mapping.debitColumn;
  final creditColumn = mapping.creditColumn;
  if (debitColumn != null || creditColumn != null) {
    final debit = debitColumn != null && debitColumn < row.length
        ? parseFlexibleAmount(row[debitColumn])
        : null;
    final credit = creditColumn != null && creditColumn < row.length
        ? parseFlexibleAmount(row[creditColumn])
        : null;
    if (debit != null && debit != 0) {
      amount = debit.abs();
      type = TransactionType.expense;
    } else if (credit != null && credit != 0) {
      amount = credit.abs();
      type = TransactionType.income;
    }
  } else {
    final amountColumn = mapping.amountColumn;
    if (amountColumn != null && amountColumn < row.length) {
      final raw = parseFlexibleAmount(row[amountColumn]);
      if (raw != null && raw != 0) {
        amount = raw.abs();
        type = raw < 0 ? TransactionType.expense : TransactionType.income;
      }
    }
  }

  final descriptionColumn = mapping.descriptionColumn;
  final description = descriptionColumn != null && descriptionColumn < row.length
      ? row[descriptionColumn]
      : '';

  return ImportedRow(date: date, amount: amount, type: type, description: description);
}

List<ImportedRow> parseImportRows(ParsedCsv csv, ImportColumnMapping mapping) =>
    csv.rows.map((row) => parseImportRow(row, mapping)).toList();

bool isDuplicateTransaction(
  ImportedRow row,
  Iterable<TransactionEntity> existing,
) {
  if (!row.isValid) return false;
  return existing.any((t) =>
      t.type == row.type &&
      t.date.year == row.date!.year &&
      t.date.month == row.date!.month &&
      t.date.day == row.date!.day &&
      (t.amount - row.amount!).abs() < 0.5);
}

List<TransactionEntity> buildImportedTransactions({
  required List<ImportedRow> rows,
  required String? accountId,
  required String defaultExpenseCategory,
  required String defaultIncomeCategory,
  required List<TransactionEntity> existing,
  required String Function() generateId,
}) {
  final result = <TransactionEntity>[];
  final combinedExisting = [...existing];

  for (final row in rows) {
    if (!row.isValid) continue;
    if (isDuplicateTransaction(row, combinedExisting)) continue;

    final tx = TransactionEntity(
      id: generateId(),
      title: row.description.trim().isEmpty
          ? (row.type == TransactionType.income ? defaultIncomeCategory : defaultExpenseCategory)
          : row.description.trim(),
      amount: row.amount!,
      type: row.type!,
      category:
          row.type == TransactionType.income ? defaultIncomeCategory : defaultExpenseCategory,
      date: row.date!,
      accountId: accountId,
    );
    result.add(tx);
    combinedExisting.add(tx);
  }
  return result;
}
