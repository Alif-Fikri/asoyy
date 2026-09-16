import 'package:equatable/equatable.dart';

class CalculatorState extends Equatable {
  final String display;
  final String expression;
  final bool justEvaluated;
  final int cursorPosition;

  const CalculatorState({
    this.display = '0',
    this.expression = '',
    this.justEvaluated = false,
    this.cursorPosition = 1,
  });

  CalculatorState copyWith({
    String? display,
    String? expression,
    bool? justEvaluated,
    int? cursorPosition,
  }) =>
      CalculatorState(
        display: display ?? this.display,
        expression: expression ?? this.expression,
        justEvaluated: justEvaluated ?? this.justEvaluated,
        cursorPosition: cursorPosition ?? this.cursorPosition,
      );

  @override
  List<Object?> get props => [display, expression, justEvaluated, cursorPosition];
}
