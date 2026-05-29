import '../../../../core/usecase/usecase.dart';
import '../entities/password_entity.dart';
import '../repositories/password_repository.dart';

class SavePassword implements UseCase<void, PasswordEntity> {
  final PasswordRepository repository;
  SavePassword(this.repository);

  @override
  Future<void> call(PasswordEntity params) => repository.savePassword(params);
}
