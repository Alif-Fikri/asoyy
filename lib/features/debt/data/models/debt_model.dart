import 'package:hive/hive.dart';
import '../../domain/entities/debt_entity.dart';

part 'debt_model.g.dart';

@HiveType(typeId: 6)
class DebtModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String personName;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final int direction;

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final bool isSettled;

  @HiveField(7)
  final DateTime? dueDate;

  DebtModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.direction,
    this.note,
    required this.date,
    required this.isSettled,
    this.dueDate,
  });

  factory DebtModel.fromEntity(DebtEntity e) => DebtModel(
        id: e.id,
        personName: e.personName,
        amount: e.amount,
        direction: e.direction.index,
        note: e.note,
        date: e.date,
        isSettled: e.isSettled,
        dueDate: e.dueDate,
      );

  DebtEntity toEntity() => DebtEntity(
        id: id,
        personName: personName,
        amount: amount,
        direction: DebtDirection.values[direction],
        note: note,
        date: date,
        isSettled: isSettled,
        dueDate: dueDate,
      );
}
