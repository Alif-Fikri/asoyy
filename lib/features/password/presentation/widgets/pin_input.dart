import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_color_theme.dart';

class PinInput extends StatefulWidget {
  final void Function(String pin) onCompleted;
  final String? errorText;

  final int resetToken;

  const PinInput({
    super.key,
    required this.onCompleted,
    this.errorText,
    this.resetToken = 0,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  static const _length = 6;
  String _entered = '';

  @override
  void didUpdateWidget(covariant PinInput old) {
    super.didUpdateWidget(old);
    if (old.resetToken != widget.resetToken) {
      setState(() => _entered = '');
    }
  }

  void _tap(String digit) {
    if (_entered.length >= _length) return;
    HapticFeedback.lightImpact();
    setState(() => _entered += digit);
    if (_entered.length == _length) {
      widget.onCompleted(_entered);
    }
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 420.0;
        final reserved = 14 + 16 + (widget.errorText != null ? 12 + 16 : 0);
        final keypadHeight = (maxH - reserved).clamp(140.0, 420.0);
        final buttonSize = (keypadHeight / 4 - 12).clamp(34.0, 72.0);
        final spacing = (buttonSize / 4).clamp(8.0, 32.0);

        return SingleChildScrollView(
          child: Column(
            children: [
              _dots(context),
              if (widget.errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.errorText!,
                  style: const TextStyle(
                    color: AppColors.alarmColor,
                    fontSize: 13,
                  ),
                ),
              ],
              SizedBox(height: spacing),
              _keypad(context, buttonSize),
            ],
          ),
        );
      },
    );
  }

  Widget _dots(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_length, (i) {
        final filled = i < _entered.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? c.textPrimary : Colors.transparent,
            border: Border.all(
              color: filled ? c.textPrimary : c.border,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _keypad(BuildContext context, double buttonSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row
                .map(
                  (d) => _KeypadButton(
                    label: d,
                    onTap: () => _tap(d),
                    size: buttonSize,
                  ),
                )
                .toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _KeypadButton.empty(size: buttonSize),
            _KeypadButton(label: '0', onTap: () => _tap('0'), size: buttonSize),
            _KeypadButton.backspace(onTap: _backspace, size: buttonSize),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onTap;
  final bool isBackspace;
  final bool isEmpty;
  final double size;

  const _KeypadButton({this.label, required this.onTap, this.size = 60})
      : isBackspace = false,
        isEmpty = false;

  const _KeypadButton.backspace({required this.onTap, this.size = 60})
      : label = null,
        isBackspace = true,
        isEmpty = false;

  const _KeypadButton.empty({this.size = 60})
      : label = null,
        onTap = null,
        isBackspace = false,
        isEmpty = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (isEmpty) {
      return SizedBox(width: size + 12, height: size + 12);
    }
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: isBackspace ? Colors.transparent : c.cardLight,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: isBackspace
                  ? Icon(
                      CupertinoIcons.delete_left,
                      color: c.textSecondary,
                      size: size * 0.36,
                    )
                  : Text(
                      label!,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: size * 0.43,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
