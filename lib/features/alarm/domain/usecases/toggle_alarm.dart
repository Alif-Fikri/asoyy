import '../../../../core/usecase/usecase.dart';
import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';

class ToggleAlarm implements UseCase<void, AlarmEntity> {
  final AlarmRepository repository;
  ToggleAlarm(this.repository);

  @override
  Future<void> call(AlarmEntity params) => repository.updateAlarm(params);
}
