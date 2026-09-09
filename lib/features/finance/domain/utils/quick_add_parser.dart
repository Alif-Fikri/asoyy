import '../entities/transaction_entity.dart';

class QuickAddResult {
  final String title;
  final double amount;
  final String category;
  final TransactionType type;

  const QuickAddResult({
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
  });
}

const _amountPattern = r'(\d[\d.,]*)\s*(ribu|rb|jt|juta|k|m)?';

const _expenseKeywords = {
  'Makan': ['kopi', 'makan', 'nasi', 'minum', 'sarapan', 'jajan', 'makanan', 'snack', 'mie', 'ayam', 'kue'],
  'Transport': ['bensin', 'ojek', 'grab', 'gojek', 'parkir', 'tol', 'transport', 'angkot', 'taxi', 'taksi', 'bus', 'kereta'],
  'Belanja': ['belanja', 'baju', 'sepatu', 'tas', 'beli'],
  'Tagihan': ['listrik', 'pulsa', 'wifi', 'internet', 'tagihan', 'pdam', 'air', 'token'],
  'Kesehatan': ['obat', 'dokter', 'vitamin', 'rumahsakit', 'klinik'],
  'Hiburan': ['nonton', 'bioskop', 'game', 'hiburan', 'netflix', 'spotify'],
  'Pendidikan': ['buku', 'kursus', 'sekolah', 'kuliah', 'les'],
};

const _incomeKeywords = {
  'Gaji': ['gaji', 'gajian'],
  'Freelance': ['freelance', 'proyek', 'project'],
  'Investasi': ['invest', 'saham', 'dividen', 'investasi'],
  'Bonus': ['bonus', 'thr'],
  'Hadiah': ['hadiah', 'kado'],
};

const _incomeSignals = ['dapat', 'terima', 'masuk', 'nerima'];

double _applySuffix(double value, String? suffix) {
  if (suffix == null) return value;
  switch (suffix.toLowerCase()) {
    case 'rb':
    case 'ribu':
    case 'k':
      return value * 1000;
    case 'jt':
    case 'juta':
    case 'm':
      return value * 1000000;
    default:
      return value;
  }
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

QuickAddResult? parseQuickAddText(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;

  final matches = RegExp(_amountPattern, caseSensitive: false).allMatches(text).toList();
  if (matches.isEmpty) return null;

  final withSuffix = matches.where((m) => m.group(2) != null).toList();
  final chosen = withSuffix.isNotEmpty ? withSuffix.last : matches.last;

  final rawNumber = chosen.group(1)!.replaceAll(RegExp(r'[.,]'), '');
  final numberValue = double.tryParse(rawNumber);
  if (numberValue == null || numberValue <= 0) return null;

  final amount = _applySuffix(numberValue, chosen.group(2));

  final remaining = (text.substring(0, chosen.start) + text.substring(chosen.end))
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final lower = remaining.toLowerCase();
  var type = TransactionType.expense;
  var category = 'Lainnya';
  var matchedCategory = false;

  for (final entry in _incomeKeywords.entries) {
    if (entry.value.any((k) => lower.contains(k))) {
      type = TransactionType.income;
      category = entry.key;
      matchedCategory = true;
      break;
    }
  }

  if (!matchedCategory && _incomeSignals.any((k) => lower.contains(k))) {
    type = TransactionType.income;
  }

  if (!matchedCategory && type == TransactionType.expense) {
    for (final entry in _expenseKeywords.entries) {
      if (entry.value.any((k) => lower.contains(k))) {
        category = entry.key;
        matchedCategory = true;
        break;
      }
    }
  }

  final title = remaining.isEmpty ? category : _capitalize(remaining);

  return QuickAddResult(
    title: title,
    amount: amount,
    category: category,
    type: type,
  );
}
