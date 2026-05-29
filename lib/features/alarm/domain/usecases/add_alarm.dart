import '../../../../core/usecase/usecase.dart';
import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';

class AddAlarm implements UseCase<void, AlarmEntity> {
  final AlarmRepository repository;
  AddAlarm(this.repository);

  @override
  Future<void> call(AlarmEntity params) => repository.addAlarm(params);
}
