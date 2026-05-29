import '../../domain/entities/password_entity.dart';
import '../../domain/repositories/password_repository.dart';
import '../datasources/password_local_datasource.dart';
import '../models/password_model.dart';

class PasswordRepositoryImpl implements PasswordRepository {
  final PasswordLocalDatasource datasource;
  PasswordRepositoryImpl(this.datasource);

  @override
  Future<List<PasswordEntity>> getPasswords() async {
    final models = await datasource.getPasswords();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> savePassword(PasswordEntity password) =>
      datasource.savePassword(PasswordModel.fromEntity(password));

  @override
  Future<void> deletePassword(String id) => datasource.deletePassword(id);
}
