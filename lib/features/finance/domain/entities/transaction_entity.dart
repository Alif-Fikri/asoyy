class TransactionEntity {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? notes;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes,
  });

  bool get isIncome => type == TransactionType.income;
}

enum TransactionType { income, expense }

abstract class FinanceCategories {
  static const List<String> income = [
    'Gaji', 'Freelance', 'Investasi', 'Bonus', 'Hadiah', 'Lainnya',
  ];
  static const List<String> expense = [
    'Makan', 'Transport', 'Belanja', 'Tagihan', 'Kesehatan',
    'Hiburan', 'Pendidikan', 'Lainnya',
  ];
}
