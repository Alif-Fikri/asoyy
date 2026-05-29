import '../../../../core/usecase/usecase.dart';
import '../repositories/calendar_repository.dart';

class DeleteEvent implements UseCase<void, String> {
  final CalendarRepository repository;
  DeleteEvent(this.repository);

  @override
  Future<void> call(String params) => repository.deleteEvent(params);
}
