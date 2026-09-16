import 'package:flutter_bloc/flutter_bloc.dart';
import 'calculator_event.dart';
import 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorBlocEvent, CalculatorState> {
  CalculatorBloc() : super(const CalculatorState()) {
    on<DigitPressed>(_onDigit);
    on<OperatorPressed>(_onOperator);
    on<EqualsPressed>(_onEquals);
    on<ClearPressed>(_onClear);
    on<BackspacePressed>(_onBackspace);
    on<DecimalPressed>(_onDecimal);
    on<PlusMinusPressed>(_onPlusMinus);
    on<PercentPressed>(_onPercent);
    on<CursorMoved>(_onCursorMoved);
  }

  double? _firstOperand;
  String? _pendingOperator;

  void _onDigit(DigitPressed event, Emitter<CalculatorState> emit) {
    if (state.justEvaluated || state.display == '0') {
      final display = event.digit;
      emit(state.copyWith(
        display: display,
        expression: _buildExpr(display),
        justEvaluated: false,
        cursorPosition: display.length,
      ));
      return;
    }

    if (state.display.length >= 12) return;

    final cursor = state.cursorPosition.clamp(0, state.display.length);
    final display = state.display.substring(0, cursor) + event.digit + state.display.substring(cursor);
    emit(state.copyWith(
      display: display,
      expression: _buildExpr(display),
      justEvaluated: false,
      cursorPosition: cursor + 1,
    ));
  }

  void _onOperator(OperatorPressed event, Emitter<CalculatorState> emit) {
    _firstOperand = double.tryParse(state.display);
    _pendingOperator = event.operator;
    emit(state.copyWith(
      expression: '${_fmt(_firstOperand ?? 0)} ${event.operator}',
      justEvaluated: true,
    ));
  }

  void _onEquals(EqualsPressed event, Emitter<CalculatorState> emit) {
    if (_firstOperand == null || _pendingOperator == null) return;
    final second = double.tryParse(state.display) ?? 0;
    final result = _calculate(_firstOperand!, _pendingOperator!, second);
    final resultStr = _fmt(result);
    emit(state.copyWith(
      display: resultStr,
      expression: '${_fmt(_firstOperand!)} $_pendingOperator ${_fmt(second)} =',
      justEvaluated: true,
      cursorPosition: resultStr.length,
    ));
    _firstOperand = null;
    _pendingOperator = null;
  }

  void _onClear(ClearPressed event, Emitter<CalculatorState> emit) {
    _firstOperand = null;
    _pendingOperator = null;
    emit(const CalculatorState());
  }

  void _onBackspace(BackspacePressed event, Emitter<CalculatorState> emit) {
    if (state.justEvaluated) return;
    final d = state.display;
    final cursor = state.cursorPosition.clamp(0, d.length);
    if (cursor == 0) return;

    if (d.length <= 1) {
      emit(state.copyWith(display: '0', expression: _buildExpr('0'), cursorPosition: 1));
      return;
    }

    final newDisplay = d.substring(0, cursor - 1) + d.substring(cursor);
    emit(state.copyWith(
      display: newDisplay,
      expression: _buildExpr(newDisplay),
      cursorPosition: cursor - 1,
    ));
  }

  void _onDecimal(DecimalPressed event, Emitter<CalculatorState> emit) {
    if (state.display.contains('.')) return;

    if (state.justEvaluated) {
      const d = '0.';
      emit(state.copyWith(
        display: d,
        expression: _buildExpr(d),
        justEvaluated: false,
        cursorPosition: d.length,
      ));
      return;
    }

    final cursor = state.cursorPosition.clamp(0, state.display.length);
    final d = '${state.display.substring(0, cursor)}.${state.display.substring(cursor)}';
    emit(state.copyWith(display: d, expression: _buildExpr(d), cursorPosition: cursor + 1));
  }

  void _onPlusMinus(PlusMinusPressed event, Emitter<CalculatorState> emit) {
    final val = double.tryParse(state.display);
    if (val == null) return;
    final toggled = _fmt(val * -1);
    emit(state.copyWith(display: toggled, expression: _buildExpr(toggled), cursorPosition: toggled.length));
  }

  void _onPercent(PercentPressed event, Emitter<CalculatorState> emit) {
    final val = double.tryParse(state.display);
    if (val == null) return;
    final pct = _fmt(val / 100);
    emit(state.copyWith(display: pct, expression: _buildExpr(pct), cursorPosition: pct.length));
  }

  void _onCursorMoved(CursorMoved event, Emitter<CalculatorState> emit) {
    emit(state.copyWith(
      cursorPosition: event.rawIndex.clamp(0, state.display.length),
      justEvaluated: false,
    ));
  }

  double _calculate(double a, String op, double b) {
    switch (op) {
      case '+': return a + b;
      case '−': return a - b;
      case '×': return a * b;
      case '÷': return b == 0 ? 0 : a / b;
      default: return b;
    }
  }

  String _fmt(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _buildExpr(String display) {
    if (_pendingOperator != null && _firstOperand != null) {
      return '${_fmt(_firstOperand!)} $_pendingOperator $display';
    }
    return display;
  }
}
