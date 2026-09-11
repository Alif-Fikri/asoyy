import '../../../../core/usecase/usecase.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class UpdateDebt implements UseCase<void, DebtEntity> {
  final DebtRepository repository;
  UpdateDebt(this.repository);

  @override
  Future<void> call(DebtEntity params) => repository.updateDebt(params);
}
