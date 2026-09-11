import '../../../../core/usecase/usecase.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

class GetDebts implements UseCase<List<DebtEntity>, NoParams> {
  final DebtRepository repository;
  GetDebts(this.repository);

  @override
  Future<List<DebtEntity>> call(NoParams params) => repository.getDebts();
}
