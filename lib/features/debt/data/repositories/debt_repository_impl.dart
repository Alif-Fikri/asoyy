import '../../domain/entities/debt_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_local_datasource.dart';
import '../models/debt_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtLocalDatasource datasource;
  DebtRepositoryImpl(this.datasource);

  @override
  Future<List<DebtEntity>> getDebts() async {
    final models = await datasource.getDebts();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addDebt(DebtEntity debt) =>
      datasource.saveDebt(DebtModel.fromEntity(debt));

  @override
  Future<void> updateDebt(DebtEntity debt) =>
      datasource.saveDebt(DebtModel.fromEntity(debt));

  @override
  Future<void> deleteDebt(String id) => datasource.deleteDebt(id);
}
