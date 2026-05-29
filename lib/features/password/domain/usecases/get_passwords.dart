import '../../../../core/usecase/usecase.dart';
import '../entities/password_entity.dart';
import '../repositories/password_repository.dart';

class GetPasswords implements UseCase<List<PasswordEntity>, NoParams> {
  final PasswordRepository repository;
  GetPasswords(this.repository);

  @override
  Future<List<PasswordEntity>> call(NoParams params) => repository.getPasswords();
}
