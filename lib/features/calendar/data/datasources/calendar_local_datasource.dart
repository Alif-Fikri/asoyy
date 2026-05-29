import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/event_model.dart';

abstract class CalendarLocalDatasource {
  Future<List<EventModel>> getEvents();
  Future<void> addEvent(EventModel event);
  Future<void> deleteEvent(String id);
}

class CalendarLocalDatasourceImpl implements CalendarLocalDatasource {
  final Box<EventModel> box;
  CalendarLocalDatasourceImpl(this.box);

  static Future<CalendarLocalDatasourceImpl> create() async {
    final box = await Hive.openBox<EventModel>(AppConstants.eventsBox);
    return CalendarLocalDatasourceImpl(box);
  }

  @override
  Future<List<EventModel>> getEvents() async => box.values.toList();

  @override
  Future<void> addEvent(EventModel event) => box.put(event.id, event);

  @override
  Future<void> deleteEvent(String id) => box.delete(id);
}
