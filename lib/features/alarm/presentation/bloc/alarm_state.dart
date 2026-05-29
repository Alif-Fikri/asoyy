import 'package:equatable/equatable.dart';
import '../../domain/entities/alarm_entity.dart';

abstract class AlarmState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AlarmInitial extends AlarmState {}

class AlarmLoading extends AlarmState {}

class AlarmLoaded extends AlarmState {
  final List<AlarmEntity> alarms;
  AlarmLoaded(this.alarms);

  AlarmLoaded copyWith({List<AlarmEntity>? alarms}) =>
      AlarmLoaded(alarms ?? this.alarms);

  @override
  List<Object?> get props => [alarms];
}

class AlarmError extends AlarmState {
  final String message;
  AlarmError(this.message);
  @override
  List<Object?> get props => [message];
}
