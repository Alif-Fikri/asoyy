import 'package:equatable/equatable.dart';

abstract class CalculatorBlocEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DigitPressed extends CalculatorBlocEvent {
  final String digit;
  DigitPressed(this.digit);
  @override
  List<Object?> get props => [digit];
}

class OperatorPressed extends CalculatorBlocEvent {
  final String operator;
  OperatorPressed(this.operator);
  @override
  List<Object?> get props => [operator];
}

class EqualsPressed extends CalculatorBlocEvent {}

class ClearPressed extends CalculatorBlocEvent {}

class BackspacePressed extends CalculatorBlocEvent {}

class DecimalPressed extends CalculatorBlocEvent {}

class PlusMinusPressed extends CalculatorBlocEvent {}

class PercentPressed extends CalculatorBlocEvent {}
