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

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes,
  });

  factory TransactionModel.fromEntity(TransactionEntity e) => TransactionModel(
        id: e.id,
        title: e.title,
        amount: e.amount,
        type: e.type == TransactionType.income ? 'income' : 'expense',
        category: e.category,
        date: e.date,
        notes: e.notes,
      );

  TransactionEntity toEntity() => TransactionEntity(
        id: id,
        title: title,
        amount: amount,
        type: type == 'income' ? TransactionType.income : TransactionType.expense,
        category: category,
        date: date,
        notes: notes,
      );
}
