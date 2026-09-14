class ScannedLine {
  final String text;
  final double top;
  final double bottom;
  final double left;

  const ScannedLine({
    required this.text,
    required this.top,
    required this.bottom,
    required this.left,
  });

  double get centerY => (top + bottom) / 2;
  double get height => (bottom - top).abs();
}

List<String> groupIntoVisualRows(List<ScannedLine> lines) {
  if (lines.isEmpty) return const [];

  final sorted = [...lines]..sort((a, b) => a.centerY.compareTo(b.centerY));
  final rows = <List<ScannedLine>>[];

  for (final line in sorted) {
    final tolerance = (line.height == 0 ? 8.0 : line.height) * 0.6;
    final current = rows.isEmpty ? null : rows.last;
    if (current != null &&
        (line.centerY - current.first.centerY).abs() <= tolerance) {
      current.add(line);
    } else {
      rows.add([line]);
    }
  }

  return rows.map((row) {
    row.sort((a, b) => a.left.compareTo(b.left));
    return row.map((l) => l.text).join(' ');
  }).toList(growable: false);
}

class ReceiptScan {
  final double? total;
  final DateTime? date;
  final String? merchant;
  final String? category;

  const ReceiptScan({this.total, this.date, this.merchant, this.category});

  bool get isEmpty => total == null && date == null && merchant == null;
}

const List<String> _totalKeywords = [
  'grand total',
  'total bayar',
  'total belanja',
  'total harga',
  'total tagihan',
  'jumlah bayar',
  'total',
  'jumlah',
];

const List<String> _amountBlocklist = [
  'sub',
  'kembali',
  'kembalian',
  'tunai',
  'cash',
  'debit',
  'kredit',
  'card',
  'ppn',
  'pajak',
  'tax',
  'diskon',
  'discount',
  'hemat',
  'poin',
  'point',
  'liter',
  'ltr',
  'harga/l',
  'harga satuan',
  'npwp',
  'no.',
  'struk',
  'nota',
];

const Map<String, List<String>> _merchantCategories = {
  'Transport': [
    'spbu', 'pertamina', 'shell', 'vivo', 'mypertamina', 'tol', 'parkir',
    'parking', 'grab', 'gojek', 'bluebird', 'bensin', 'pom bensin',
  ],
  'Belanja': [
    'indomaret', 'alfamart', 'alfamidi', 'superindo', 'hypermart', 'transmart',
    'carrefour', 'giant', 'lotte', 'ace hardware', 'matahari', 'uniqlo',
    'ramayana', 'hypermarket', 'supermarket', 'minimarket',
  ],
  'Makan': [
    'kfc', 'mcd', 'mcdonald', 'burger king', 'pizza', 'starbucks', 'kopi',
    'cafe', 'kafe', 'resto', 'restaurant', 'restoran', 'warung', 'bakso',
    'sate', 'padang', 'hokben', 'solaria', 'richeese', 'chatime', 'janji jiwa',
    'kenangan', 'dunkin', 'breadtalk', 'holland bakery', 'ayam', 'mie',
  ],
  'Kesehatan': [
    'apotek', 'apotik', 'kimia farma', 'guardian', 'century', 'klinik',
    'rumah sakit', 'pharmacy', 'farma',
  ],
  'Hiburan': ['cgv', 'xxi', 'cinema', 'cineplex', 'timezone', 'bioskop'],
  'Tagihan': ['pln', 'pdam', 'telkom', 'indihome', 'listrik'],
};

final RegExp _amountPattern = RegExp(r'(\d[\d.,]*\d|\d)');
final RegExp _datePattern = RegExp(
  r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})|(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})',
);

double? parseReceiptAmount(String raw) {
  var text = raw.replaceAll(RegExp(r'[^\d.,]'), '');
  if (text.isEmpty) return null;

  final lastDot = text.lastIndexOf('.');
  final lastComma = text.lastIndexOf(',');
  final decimalAt = lastDot > lastComma ? lastDot : lastComma;

  if (decimalAt >= 0) {
    final tail = text.substring(decimalAt + 1);
    if (tail.length == 2 && !tail.contains(RegExp(r'[.,]'))) {
      final whole = text.substring(0, decimalAt).replaceAll(RegExp(r'[.,]'), '');
      if (whole.isEmpty) return null;
      return double.tryParse('$whole.$tail');
    }
  }

  final digits = text.replaceAll(RegExp(r'[.,]'), '');
  if (digits.isEmpty) return null;
  return double.tryParse(digits);
}

bool _blocked(String lower) =>
    _amountBlocklist.any((word) => lower.contains(word));

double? _amountFromLine(String line) {
  final matches = _amountPattern.allMatches(line).toList();
  if (matches.isEmpty) return null;
  for (final match in matches.reversed) {
    final value = parseReceiptAmount(match.group(0)!);
    if (value != null && value > 0) return value;
  }
  return null;
}

double? findReceiptTotal(List<String> lines) {
  for (final keyword in _totalKeywords) {
    for (var i = lines.length - 1; i >= 0; i--) {
      final lower = lines[i].toLowerCase();
      if (!lower.contains(keyword)) continue;
      if (_blocked(lower)) continue;

      final sameLine = _amountFromLine(lines[i]);
      if (sameLine != null) return sameLine;

      if (i + 1 < lines.length && !_blocked(lines[i + 1].toLowerCase())) {
        final nextLine = _amountFromLine(lines[i + 1]);
        if (nextLine != null) return nextLine;
      }
    }
  }
  return null;
}

DateTime? findReceiptDate(List<String> lines, DateTime now) {
  for (final line in lines) {
    for (final match in _datePattern.allMatches(line)) {
      final DateTime? parsed;
      if (match.group(1) != null) {
        parsed = _buildDate(
          int.parse(match.group(3)!),
          int.parse(match.group(2)!),
          int.parse(match.group(1)!),
        );
      } else {
        parsed = _buildDate(
          int.parse(match.group(4)!),
          int.parse(match.group(5)!),
          int.parse(match.group(6)!),
        );
      }
      if (parsed == null) continue;
      if (parsed.isAfter(now.add(const Duration(days: 1)))) continue;
      if (parsed.year < now.year - 5) continue;
      return parsed;
    }
  }
  return null;
}

DateTime? _buildDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final fullYear = year < 100 ? 2000 + year : year;
  final built = DateTime(fullYear, month, day);
  if (built.month != month || built.day != day) return null;
  return built;
}

String? findReceiptMerchant(List<String> lines) {
  for (final line in lines.take(5)) {
    final trimmed = line.trim();
    if (trimmed.length < 3) continue;
    final letters = trimmed.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 3) continue;
    if (letters.length < trimmed.length / 2) continue;
    return trimmed;
  }
  return null;
}

String? categoryForReceipt(List<String> lines) {
  final haystack = lines.join(' ').toLowerCase();
  String? best;
  var bestLength = 0;
  for (final entry in _merchantCategories.entries) {
    for (final keyword in entry.value) {
      if (keyword.length <= bestLength) continue;
      if (!haystack.contains(keyword)) continue;
      best = entry.key;
      bestLength = keyword.length;
    }
  }
  return best;
}

ReceiptScan parseReceipt(List<String> rawLines, {DateTime? now}) {
  final lines = rawLines
      .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((l) => l.isNotEmpty)
      .toList(growable: false);

  if (lines.isEmpty) return const ReceiptScan();

  return ReceiptScan(
    total: findReceiptTotal(lines),
    date: findReceiptDate(lines, now ?? DateTime.now()),
    merchant: findReceiptMerchant(lines),
    category: categoryForReceipt(lines),
  );
}
