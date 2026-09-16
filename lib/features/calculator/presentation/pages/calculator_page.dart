import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../domain/format_calculator_display.dart';
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
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildDisplay(context, state, bloc)),
                _buildKeypad(bloc),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisplay(BuildContext context, CalculatorState state, CalculatorBloc bloc) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (state.expression.isNotEmpty)
            Text(
              formatCalculatorExpression(state.expression),
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),
          _CalcDisplayField(
            rawDisplay: state.display,
            cursorPosition: state.cursorPosition,
            textColor: c.textPrimary,
            onCursorMoved: (rawIndex) => bloc.add(CursorMoved(rawIndex)),
          ),
          const SizedBox(height: 10),
          IconButton(
            onPressed: () => bloc.add(BackspacePressed()),
            icon: Icon(CupertinoIcons.delete_left, color: c.textSecondary, size: 22),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
            CalcButton(label: '0', flex: 2, onTap: () => bloc.add(DigitPressed('0'))),
            CalcButton(label: '.', onTap: () => bloc.add(DecimalPressed())),
            CalcButton(label: '=', style: CalcButtonStyle.equals, onTap: () => bloc.add(EqualsPressed())),
          ]),
        ],
      ),
    );
  }
}

class _CalcDisplayField extends StatefulWidget {
  final String rawDisplay;
  final int cursorPosition;
  final Color textColor;
  final ValueChanged<int> onCursorMoved;

  const _CalcDisplayField({
    required this.rawDisplay,
    required this.cursorPosition,
    required this.textColor,
    required this.onCursorMoved,
  });

  @override
  State<_CalcDisplayField> createState() => _CalcDisplayFieldState();
}

class _CalcDisplayFieldState extends State<_CalcDisplayField> {
  late final TextEditingController _controller;
  bool _applyingExternalChange = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatCalculatorDisplay(widget.rawDisplay),
    );
    _syncSelection();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _CalcDisplayField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawDisplay != widget.rawDisplay || oldWidget.cursorPosition != widget.cursorPosition) {
      _applyingExternalChange = true;
      _controller.text = formatCalculatorDisplay(widget.rawDisplay);
      _syncSelection();
      _applyingExternalChange = false;
    }
  }

  void _syncSelection() {
    final formattedIndex = rawIndexToFormattedIndex(widget.rawDisplay, widget.cursorPosition);
    _controller.selection = TextSelection.collapsed(offset: formattedIndex);
  }

  void _onControllerChanged() {
    if (_applyingExternalChange) return;
    final rawIndex = formattedIndexToRawIndex(_controller.text, _controller.selection.baseOffset);
    widget.onCursorMoved(rawIndex);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  double _fontSizeFor(int length) {
    if (length <= 8) return 48;
    if (length <= 11) return 38;
    if (length <= 14) return 30;
    return 24;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: true,
      showCursor: true,
      textAlign: TextAlign.right,
      maxLines: 1,
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      style: TextStyle(
        color: widget.textColor,
        fontSize: _fontSizeFor(_controller.text.length),
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
      ),
    );
  }
}
