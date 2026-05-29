import '../entities/event_entity.dart';

abstract class CalendarRepository {
  Future<List<EventEntity>> getEvents();
  Future<void> addEvent(EventEntity event);
  Future<void> deleteEvent(String id);
}
