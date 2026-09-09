import 'transaction_entity.dart';

class RecurringTransactionEntity {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final int dayOfMonth;
  final String? notes;
  final String? lastGeneratedMonth;

  const RecurringTransactionEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.dayOfMonth,
    this.notes,
    this.lastGeneratedMonth,
  });

  bool get isIncome => type == TransactionType.income;

  RecurringTransactionEntity copyWith({String? lastGeneratedMonth}) =>
      RecurringTransactionEntity(
        id: id,
        title: title,
        amount: amount,
        type: type,
        category: category,
        dayOfMonth: dayOfMonth,
        notes: notes,
        lastGeneratedMonth: lastGeneratedMonth ?? this.lastGeneratedMonth,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type == TransactionType.income ? 'income' : 'expense',
        'category': category,
        'dayOfMonth': dayOfMonth,
        'notes': notes,
        'lastGeneratedMonth': lastGeneratedMonth,
      };

  factory RecurringTransactionEntity.fromJson(Map<String, dynamic> json) =>
      RecurringTransactionEntity(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        category: json['category'] as String,
        dayOfMonth: json['dayOfMonth'] as int,
        notes: json['notes'] as String?,
        lastGeneratedMonth: json['lastGeneratedMonth'] as String?,
      );
}
