import 'package:hive/hive.dart';
import '../../domain/entities/transaction_entity.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 3)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final String? accountId;

  @HiveField(8)
  final String? toAccountId;

  TransactionModel({
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

  factory TransactionModel.fromEntity(TransactionEntity e) => TransactionModel(
        id: e.id,
        title: e.title,
        amount: e.amount,
        type: e.type.name,
        category: e.category,
        date: e.date,
        notes: e.notes,
        accountId: e.accountId,
        toAccountId: e.toAccountId,
      );

  TransactionEntity toEntity() => TransactionEntity(
        id: id,
        title: title,
        amount: amount,
        type: _typeFromString(type),
        category: category,
        date: date,
        notes: notes,
        accountId: accountId,
        toAccountId: toAccountId,
      );

  static TransactionType _typeFromString(String raw) {
    for (final t in TransactionType.values) {
      if (t.name == raw) return t;
    }
    return TransactionType.expense;
  }
}
