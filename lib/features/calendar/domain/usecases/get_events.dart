import '../../../../core/usecase/usecase.dart';
import '../entities/event_entity.dart';
import '../repositories/calendar_repository.dart';

class GetEvents implements UseCase<List<EventEntity>, NoParams> {
  final CalendarRepository repository;
  GetEvents(this.repository);

  @override
  Future<List<EventEntity>> call(NoParams params) => repository.getEvents();
}
