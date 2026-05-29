import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/get_events.dart';
import '../../domain/usecases/add_event.dart';
import '../../domain/usecases/delete_event.dart';
import '../../../../core/usecase/usecase.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarBlocEvent, CalendarState> {
  final GetEvents getEvents;
  final AddEvent addEvent;
  final DeleteEvent deleteEvent;

  CalendarBloc({
    required this.getEvents,
    required this.addEvent,
    required this.deleteEvent,
  }) : super(CalendarInitial()) {
    on<LoadEvents>(_onLoad);
    on<AddEventRequested>(_onAdd);
    on<DeleteEventRequested>(_onDelete);
    on<SelectDay>(_onSelectDay);
    on<SetPayday>(_onSetPayday);
  }

  int? _loadPayday() {
    final box = Hive.box(AppConstants.settingsBox);
    final v = box.get('payday_day');
    return v is int ? v : null;
  }

  Future<void> _onLoad(LoadEvents event, Emitter<CalendarState> emit) async {
    emit(CalendarLoading());
    try {
      final events = await getEvents(const NoParams());
      emit(CalendarLoaded(
        events: events,
        paydayDay: _loadPayday(),
        selectedDay: DateTime.now(),
        focusedDay: DateTime.now(),
      ));
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }

  Future<void> _onAdd(AddEventRequested event, Emitter<CalendarState> emit) async {
    if (state is CalendarLoaded) {
      final cur = state as CalendarLoaded;
      await addEvent(event.event);
      emit(cur.copyWith(events: [...cur.events, event.event]));
    }
  }

  Future<void> _onDelete(DeleteEventRequested event, Emitter<CalendarState> emit) async {
    if (state is CalendarLoaded) {
      final cur = state as CalendarLoaded;
      await deleteEvent(event.id);
      emit(cur.copyWith(events: cur.events.where((e) => e.id != event.id).toList()));
    }
  }

  void _onSelectDay(SelectDay event, Emitter<CalendarState> emit) {
    if (state is CalendarLoaded) {
      final cur = state as CalendarLoaded;
      emit(cur.copyWith(selectedDay: event.day, focusedDay: event.day));
    }
  }

  void _onSetPayday(SetPayday event, Emitter<CalendarState> emit) {
    if (state is CalendarLoaded) {
      final box = Hive.box(AppConstants.settingsBox);
      if (event.day == null) {
        box.delete('payday_day');
      } else {
        box.put('payday_day', event.day);
      }
      final cur = state as CalendarLoaded;
      emit(cur.copyWith(paydayDay: () => event.day));
    }
  }
}
