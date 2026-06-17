import 'package:equatable/equatable.dart';
import '../../domain/entities/alarm_entity.dart';

abstract class AlarmBlocEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAlarms extends AlarmBlocEvent {}

class AddAlarmRequested extends AlarmBlocEvent {
  final AlarmEntity alarm;
  final String stopButtonText;
  AddAlarmRequested(this.alarm, {this.stopButtonText = 'Stop'});
  @override
  List<Object?> get props => [alarm.id];
}

class ToggleAlarmRequested extends AlarmBlocEvent {
  final AlarmEntity alarm;
  final String stopButtonText;
  ToggleAlarmRequested(this.alarm, {this.stopButtonText = 'Stop'});
  @override
  List<Object?> get props => [alarm.id];
}

class DeleteAlarmRequested extends AlarmBlocEvent {
  final String id;
  DeleteAlarmRequested(this.id);
  @override
  List<Object?> get props => [id];
}
