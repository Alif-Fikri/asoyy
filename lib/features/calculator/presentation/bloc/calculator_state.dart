import 'package:equatable/equatable.dart';

class CalculatorState extends Equatable {
  final String display;
  final String expression;
  final bool justEvaluated;

  const CalculatorState({
    this.display = '0',
    this.expression = '',
    this.justEvaluated = false,
  });

  CalculatorState copyWith({
    String? display,
    String? expression,
    bool? justEvaluated,
  }) =>
      CalculatorState(
        display: display ?? this.display,
        expression: expression ?? this.expression,
        justEvaluated: justEvaluated ?? this.justEvaluated,
      );

  @override
  List<Object?> get props => [display, expression, justEvaluated];
}
