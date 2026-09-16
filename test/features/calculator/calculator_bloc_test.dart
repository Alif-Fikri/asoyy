import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/calculator/presentation/bloc/calculator_bloc.dart';
import 'package:asoyy/features/calculator/presentation/bloc/calculator_event.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('CalculatorBloc cursor-aware editing', () {
    test('typing digits appends at the end by default', () async {
      final bloc = CalculatorBloc();
      bloc.add(DigitPressed('1'));
      bloc.add(DigitPressed('2'));
      bloc.add(DigitPressed('3'));
      await _settle();

      expect(bloc.state.display, '123');
      expect(bloc.state.cursorPosition, 3);
      await bloc.close();
    });

    test('moving the cursor to the middle inserts the next digit there', () async {
      final bloc = CalculatorBloc();
      bloc.add(DigitPressed('1'));
      bloc.add(DigitPressed('2'));
      bloc.add(DigitPressed('3'));
      bloc.add(CursorMoved(1));
      bloc.add(DigitPressed('9'));
      await _settle();

      expect(bloc.state.display, '1923');
      expect(bloc.state.cursorPosition, 2);
      await bloc.close();
    });

    test('backspace at a mid-string cursor removes the digit just before it', () async {
      final bloc = CalculatorBloc();
      bloc.add(DigitPressed('1'));
      bloc.add(DigitPressed('2'));
      bloc.add(DigitPressed('3'));
      bloc.add(CursorMoved(2));
      bloc.add(BackspacePressed());
      await _settle();

      expect(bloc.state.display, '13');
      expect(bloc.state.cursorPosition, 1);
      await bloc.close();
    });

    test('a decimal point can be inserted mid-string too', () async {
      final bloc = CalculatorBloc();
      bloc.add(DigitPressed('1'));
      bloc.add(DigitPressed('2'));
      bloc.add(DigitPressed('3'));
      bloc.add(CursorMoved(1));
      bloc.add(DecimalPressed());
      await _settle();

      expect(bloc.state.display, '1.23');
      expect(bloc.state.cursorPosition, 2);
      await bloc.close();
    });

    test('tapping into a freshly evaluated result switches it back to editable', () async {
      final bloc = CalculatorBloc();
      bloc.add(DigitPressed('4'));
      bloc.add(OperatorPressed('+'));
      bloc.add(DigitPressed('2'));
      bloc.add(EqualsPressed());
      await _settle();
      bloc.add(CursorMoved(1));
      bloc.add(DigitPressed('0'));
      await _settle();

      expect(bloc.state.display, '60');
      expect(bloc.state.justEvaluated, isFalse);
      await bloc.close();
    });

    test('starting a fresh number after clear resets the cursor to the end', () async {
      final bloc = CalculatorBloc();
      bloc.add(DigitPressed('5'));
      bloc.add(ClearPressed());
      bloc.add(DigitPressed('7'));
      await _settle();

      expect(bloc.state.display, '7');
      expect(bloc.state.cursorPosition, 1);
      await bloc.close();
    });
  });
}
