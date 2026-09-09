import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../bloc/calculator_bloc.dart';
import '../bloc/calculator_event.dart';
import '../bloc/calculator_state.dart';
import '../widgets/calc_button.dart';

class CalculatorPage extends StatelessWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        final bloc = context.read<CalculatorBloc>();
        return Scaffold(
          backgroundColor: c.background,
          appBar: AppBar(title: Text(context.strings.calc_title)),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildDisplay(context, state)),
              _buildKeypad(bloc),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisplay(BuildContext context, CalculatorState state) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (state.expression.isNotEmpty)
            Text(
              state.expression,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              state.display,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 64,
                fontWeight: FontWeight.w300,
                letterSpacing: -2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(CalculatorBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(children: [
            CalcButton(label: 'AC', style: CalcButtonStyle.action, onTap: () => bloc.add(ClearPressed())),
            CalcButton(label: '+/-', style: CalcButtonStyle.action, onTap: () => bloc.add(PlusMinusPressed())),
            CalcButton(label: '%', style: CalcButtonStyle.action, onTap: () => bloc.add(PercentPressed())),
            CalcButton(label: '÷', style: CalcButtonStyle.operator, onTap: () => bloc.add(OperatorPressed('÷'))),
          ]),
          Row(children: [
            CalcButton(label: '7', onTap: () => bloc.add(DigitPressed('7'))),
            CalcButton(label: '8', onTap: () => bloc.add(DigitPressed('8'))),
            CalcButton(label: '9', onTap: () => bloc.add(DigitPressed('9'))),
            CalcButton(label: '×', style: CalcButtonStyle.operator, onTap: () => bloc.add(OperatorPressed('×'))),
          ]),
          Row(children: [
            CalcButton(label: '4', onTap: () => bloc.add(DigitPressed('4'))),
            CalcButton(label: '5', onTap: () => bloc.add(DigitPressed('5'))),
            CalcButton(label: '6', onTap: () => bloc.add(DigitPressed('6'))),
            CalcButton(label: '−', style: CalcButtonStyle.operator, onTap: () => bloc.add(OperatorPressed('−'))),
          ]),
          Row(children: [
            CalcButton(label: '1', onTap: () => bloc.add(DigitPressed('1'))),
            CalcButton(label: '2', onTap: () => bloc.add(DigitPressed('2'))),
            CalcButton(label: '3', onTap: () => bloc.add(DigitPressed('3'))),
            CalcButton(label: '+', style: CalcButtonStyle.operator, onTap: () => bloc.add(OperatorPressed('+'))),
          ]),
          Row(children: [
            CalcButton(label: '⌫', style: CalcButtonStyle.action, onTap: () => bloc.add(BackspacePressed())),
            CalcButton(label: '0', onTap: () => bloc.add(DigitPressed('0'))),
            CalcButton(label: '.', onTap: () => bloc.add(DecimalPressed())),
            CalcButton(label: '=', style: CalcButtonStyle.equals, onTap: () => bloc.add(EqualsPressed())),
          ]),
        ],
      ),
    );
  }
}
