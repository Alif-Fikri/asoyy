import '../../../../core/usecase/usecase.dart';
import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';

class GetAlarms implements UseCase<List<AlarmEntity>, NoParams> {
  final AlarmRepository repository;
  GetAlarms(this.repository);

  @override
  Future<List<AlarmEntity>> call(NoParams params) => repository.getAlarms();
}
