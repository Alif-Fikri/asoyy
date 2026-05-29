import '../../domain/entities/alarm_entity.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../datasources/alarm_local_datasource.dart';
import '../models/alarm_model.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  final AlarmLocalDatasource datasource;
  AlarmRepositoryImpl(this.datasource);

  @override
  Future<List<AlarmEntity>> getAlarms() async {
    final models = await datasource.getAlarms();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addAlarm(AlarmEntity alarm) =>
      datasource.saveAlarm(AlarmModel.fromEntity(alarm));

  @override
  Future<void> updateAlarm(AlarmEntity alarm) =>
      datasource.saveAlarm(AlarmModel.fromEntity(alarm));

  @override
  Future<void> deleteAlarm(String id) => datasource.deleteAlarm(id);
}
