import 'package:hive/hive.dart';
import '../../domain/entities/bill_entity.dart';
import 'participant_model.dart';

part 'bill_model.g.dart';

@HiveType(typeId: 4)
class BillModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double totalAmount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final List<ParticipantModel> participants;

  @HiveField(5)
  final bool splitEqually;

  BillModel({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.date,
    required this.participants,
    required this.splitEqually,
  });

  factory BillModel.fromEntity(BillEntity e) => BillModel(
        id: e.id,
        title: e.title,
        totalAmount: e.totalAmount,
        date: e.date,
        participants:
            e.participants.map((p) => ParticipantModel.fromEntity(p)).toList(),
        splitEqually: e.splitEqually,
      );

  BillEntity toEntity() => BillEntity(
        id: id,
        title: title,
        totalAmount: totalAmount,
        date: date,
        participants: participants.map((p) => p.toEntity()).toList(),
        splitEqually: splitEqually,
      );
}
