import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/alarm_model.dart';

abstract class AlarmLocalDatasource {
  Future<List<AlarmModel>> getAlarms();
  Future<void> saveAlarm(AlarmModel alarm);
  Future<void> deleteAlarm(String id);
}

class AlarmLocalDatasourceImpl implements AlarmLocalDatasource {
  final Box<AlarmModel> box;
  AlarmLocalDatasourceImpl(this.box);

  static Future<AlarmLocalDatasourceImpl> create() async {
    final box = await Hive.openBox<AlarmModel>(AppConstants.alarmsBox);
    return AlarmLocalDatasourceImpl(box);
  }

  @override
  Future<List<AlarmModel>> getAlarms() async => box.values.toList();

  @override
  Future<void> saveAlarm(AlarmModel alarm) => box.put(alarm.id, alarm);

  @override
  Future<void> deleteAlarm(String id) => box.delete(id);
}
