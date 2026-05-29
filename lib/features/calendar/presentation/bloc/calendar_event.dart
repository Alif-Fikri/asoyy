import 'package:equatable/equatable.dart';
import '../../domain/entities/event_entity.dart';

abstract class CalendarBlocEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadEvents extends CalendarBlocEvent {}

class AddEventRequested extends CalendarBlocEvent {
  final EventEntity event;
  AddEventRequested(this.event);
  @override
  List<Object?> get props => [event.id];
}

class DeleteEventRequested extends CalendarBlocEvent {
  final String id;
  DeleteEventRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class SelectDay extends CalendarBlocEvent {
  final DateTime day;
  SelectDay(this.day);
  @override
  List<Object?> get props => [day];
}

class SetPayday extends CalendarBlocEvent {
  final int? day;
  SetPayday(this.day);
  @override
  List<Object?> get props => [day];
}
