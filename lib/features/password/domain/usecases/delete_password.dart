import '../../../../core/usecase/usecase.dart';
import '../repositories/password_repository.dart';

class DeletePassword implements UseCase<void, String> {
  final PasswordRepository repository;
  DeletePassword(this.repository);

  @override
  Future<void> call(String params) => repository.deletePassword(params);
}
