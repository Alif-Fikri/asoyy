import 'package:hive/hive.dart';
import '../../domain/entities/bill_entity.dart';

part 'participant_model.g.dart';

@HiveType(typeId: 5)
class ParticipantModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final bool isPaid;

  ParticipantModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.isPaid,
  });

  factory ParticipantModel.fromEntity(ParticipantEntity e) => ParticipantModel(
        id: e.id,
        name: e.name,
        amount: e.amount,
        isPaid: e.isPaid,
      );

  ParticipantEntity toEntity() => ParticipantEntity(
        id: id,
        name: name,
        amount: amount,
        isPaid: isPaid,
      );
}
