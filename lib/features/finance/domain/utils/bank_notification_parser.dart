import '../entities/transaction_entity.dart';
import 'finance_csv_import.dart';

const List<String> knownBankPackages = [
  'com.bca',
  'com.bca.mybca.omni.android',
  'id.co.bri.brimo',
  'com.gojek.app',
  'id.co.bankbkemobile.digitalbank',
  'id.bmri.livin',
  'src.com.bni',
  'id.dana',
  'ovo.id',
  'com.shopeepay.id',
];

const List<String> _incomeKeywords = [
  'menerima', 'diterima', 'masuk ke', 'kredit', 'top up berhasil',
  'saldo bertambah', 'received', 'credited', 'top-up berhasil',
  'transfer masuk', 'uang masuk', 'dana masuk', 'terima uang',
  'terima transfer', 'cashback', 'refund', 'pengembalian dana',
  'setoran berhasil', 'gaji masuk', 'pemasukan',
];

const List<String> _expenseKeywords = [
  'mengirim', 'dikirim', 'terkirim', 'keluar dari', 'debet', 'debit',
  'pembayaran berhasil', 'berhasil membayar', 'bayar', 'purchase',
  'sent', 'paid', 'penarikan', 'ditarik', 'transfer keluar', 'uang keluar',
  'dana keluar', 'kirim uang', 'tarik tunai', 'qris berhasil',
  'bayar tagihan', 'autodebet', 'auto debet', 'pembelian', 'pengeluaran',
  'potongan', 'biaya admin',
];

final RegExp _amountPattern = RegExp(r'Rp\.?\s?[\d][\d.,]*', caseSensitive: false);

class ParsedBankNotification {
  final double amount;
  final TransactionType type;
  final String description;

  const ParsedBankNotification({
    required this.amount,
    required this.type,
    required this.description,
  });
}

bool isKnownBankPackage(String packageName) =>
    knownBankPackages.any((p) => packageName.toLowerCase().contains(p.toLowerCase()));

TransactionType? _detectDirection(String text) {
  final lower = text.toLowerCase();
  final hasIncome = _incomeKeywords.any(lower.contains);
  final hasExpense = _expenseKeywords.any(lower.contains);
  if (hasIncome == hasExpense) return null;
  return hasIncome ? TransactionType.income : TransactionType.expense;
}

double? _extractAmount(String text) {
  final match = _amountPattern.firstMatch(text);
  if (match == null) return null;
  final raw = match.group(0)!;
  return parseFlexibleAmount(raw);
}

ParsedBankNotification? parseBankNotification({
  required String title,
  required String text,
}) {
  final combined = '$title $text';
  final type = _detectDirection(combined);
  if (type == null) return null;

  final amount = _extractAmount(combined);
  if (amount == null || amount <= 0) return null;

  final description = title.trim().isEmpty ? text.trim() : title.trim();

  return ParsedBankNotification(
    amount: amount,
    type: type,
    description: description,
  );
}
