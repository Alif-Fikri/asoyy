class TransactionEntity {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? notes;
  final String? accountId;
  final String? toAccountId;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes,
    this.accountId,
    this.toAccountId,
  });

  bool get isIncome => type == TransactionType.income;

  bool get isExpense => type == TransactionType.expense;

  bool get isTransfer => type == TransactionType.transfer;

  TransactionEntity copyWith({String? accountId, String? toAccountId}) =>
      TransactionEntity(
        id: id,
        title: title,
        amount: amount,
        type: type,
        category: category,
        date: date,
        notes: notes,
        accountId: accountId ?? this.accountId,
        toAccountId: toAccountId ?? this.toAccountId,
      );
}

enum TransactionType { income, expense, transfer }

const String transferCategory = 'Transfer';

abstract class FinanceCategories {
  static const List<String> income = [
    'Gaji', 'Freelance', 'Investasi', 'Bonus', 'Hadiah', 'Lainnya',
  ];
  static const List<String> expense = [
    'Makan', 'Transport', 'Belanja', 'Tagihan', 'Langganan', 'Kesehatan',
    'Hiburan', 'Pendidikan', 'Lainnya',
  ];
}
