import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_alarms.dart';
import '../../domain/usecases/add_alarm.dart';
import '../../domain/usecases/toggle_alarm.dart';
import '../../domain/usecases/delete_alarm.dart';
import '../../services/notification_service.dart';
import '../../../../core/usecase/usecase.dart';
import 'alarm_event.dart';
import 'alarm_state.dart';

class AlarmBloc extends Bloc<AlarmBlocEvent, AlarmState> {
  final GetAlarms getAlarms;
  final AddAlarm addAlarm;
  final ToggleAlarm toggleAlarm;
  final DeleteAlarm deleteAlarm;
  final NotificationService notificationService;

  AlarmBloc({
    required this.getAlarms,
    required this.addAlarm,
    required this.toggleAlarm,
    required this.deleteAlarm,
    required this.notificationService,
  }) : super(AlarmInitial()) {
    on<LoadAlarms>(_onLoad);
    on<AddAlarmRequested>(_onAdd);
    on<ToggleAlarmRequested>(_onToggle);
    on<DeleteAlarmRequested>(_onDelete);
  }

  Future<void> _onLoad(LoadAlarms event, Emitter<AlarmState> emit) async {
    emit(AlarmLoading());
    try {
      final alarms = await getAlarms(const NoParams());
      emit(AlarmLoaded(alarms));
    } catch (e) {
      emit(AlarmError(e.toString()));
    }
  }

  Future<void> _onAdd(AddAlarmRequested event, Emitter<AlarmState> emit) async {
    if (state is! AlarmLoaded) return;
    final current = state as AlarmLoaded;
    await addAlarm(event.alarm);
    await notificationService.scheduleAlarm(event.alarm);
    emit(current.copyWith(alarms: [...current.alarms, event.alarm]));
  }

  Future<void> _onToggle(ToggleAlarmRequested event, Emitter<AlarmState> emit) async {
    if (state is! AlarmLoaded) return;
    final current = state as AlarmLoaded;
    await toggleAlarm(event.alarm);
    if (event.alarm.isEnabled) {
      await notificationService.scheduleAlarm(event.alarm);
    } else {
      await notificationService.cancelAlarm(event.alarm.id);
    }
    final updated = current.alarms.map((a) => a.id == event.alarm.id ? event.alarm : a).toList();
    emit(current.copyWith(alarms: updated));
  }

  Future<void> _onDelete(DeleteAlarmRequested event, Emitter<AlarmState> emit) async {
    if (state is! AlarmLoaded) return;
    final current = state as AlarmLoaded;
    await deleteAlarm(event.id);
    await notificationService.cancelAlarm(event.id);
    final updated = current.alarms.where((a) => a.id != event.id).toList();
    emit(current.copyWith(alarms: updated));
  }
}
