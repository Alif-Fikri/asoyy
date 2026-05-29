import '../../../../core/usecase/usecase.dart';
import '../repositories/alarm_repository.dart';

class DeleteAlarm implements UseCase<void, String> {
  final AlarmRepository repository;
  DeleteAlarm(this.repository);

  @override
  Future<void> call(String params) => repository.deleteAlarm(params);
}
