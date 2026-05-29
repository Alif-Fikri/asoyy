import '../../../../core/usecase/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/calendar_repository.dart';

class AddEvent implements UseCase<void, EventEntity> {
  final CalendarRepository repository;
  AddEvent(this.repository);

  @override
  Future<void> call(EventEntity params) => repository.addEvent(params);
}
