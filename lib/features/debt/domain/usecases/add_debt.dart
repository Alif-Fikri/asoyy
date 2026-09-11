import '../../../../core/usecase/usecase.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class AddDebt implements UseCase<void, DebtEntity> {
  final DebtRepository repository;
  AddDebt(this.repository);

  @override
  Future<void> call(DebtEntity params) => repository.addDebt(params);
}
