import 'package:hive/hive.dart';
import '../../domain/entities/account_entity.dart';

part 'account_model.g.dart';

@HiveType(typeId: 7)
class AccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final double initialBalance;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
  });

  factory AccountModel.fromEntity(AccountEntity e) => AccountModel(
        id: e.id,
        name: e.name,
        type: e.type.name,
        initialBalance: e.initialBalance,
      );

  AccountEntity toEntity() => AccountEntity(
        id: id,
        name: name,
        type: accountTypeFromString(type),
        initialBalance: initialBalance,
      );
}
