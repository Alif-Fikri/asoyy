import '../../../../core/usecase/usecase.dart';
import '../repositories/debt_repository.dart';

class DeleteDebt implements UseCase<void, String> {
  final DebtRepository repository;
  DeleteDebt(this.repository);

  @override
  Future<void> call(String params) => repository.deleteDebt(params);
}
