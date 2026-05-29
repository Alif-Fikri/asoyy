import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_local_datasource.dart';
import '../models/event_model.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarLocalDatasource datasource;
  CalendarRepositoryImpl(this.datasource);

  @override
  Future<List<EventEntity>> getEvents() async {
    final models = await datasource.getEvents();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addEvent(EventEntity event) =>
      datasource.addEvent(EventModel.fromEntity(event));

  @override
  Future<void> deleteEvent(String id) => datasource.deleteEvent(id);
}
