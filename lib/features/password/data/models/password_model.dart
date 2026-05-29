import 'package:hive/hive.dart';
import '../../domain/entities/password_entity.dart';

part 'password_model.g.dart';

@HiveType(typeId: 2)
class PasswordModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String username;

  @HiveField(3)
  final String password;

  @HiveField(4)
  final String? website;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final DateTime createdAt;

  PasswordModel({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.website,
    this.notes,
    required this.createdAt,
  });

  factory PasswordModel.fromEntity(PasswordEntity e) => PasswordModel(
        id: e.id,
        title: e.title,
        username: e.username,
        password: e.password,
        website: e.website,
        notes: e.notes,
        createdAt: e.createdAt,
      );

  PasswordEntity toEntity() => PasswordEntity(
        id: id,
        title: title,
        username: username,
        password: password,
        website: website,
        notes: notes,
        createdAt: createdAt,
      );
}
