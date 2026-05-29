import '../entities/alarm_entity.dart';

abstract class AlarmRepository {
  Future<List<AlarmEntity>> getAlarms();
  Future<void> addAlarm(AlarmEntity alarm);
  Future<void> updateAlarm(AlarmEntity alarm);
  Future<void> deleteAlarm(String id);
}
