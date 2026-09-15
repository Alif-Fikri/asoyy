import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_color_theme.dart';
import '../theme/design_tokens.dart';

const double resizableFieldMinHeight = 56;
const double resizableFieldMaxHeight = 320;

class ResizableTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final double initialHeight;

  const ResizableTextField({
    super.key,
    required this.label,
    this.controller,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.initialHeight = resizableFieldMinHeight,
  });

  @override
  State<ResizableTextField> createState() => _ResizableTextFieldState();
}

class _ResizableTextFieldState extends State<ResizableTextField> {
  late double _height;

  @override
  void initState() {
    super.initState();
    _height = widget.initialHeight.clamp(
      resizableFieldMinHeight,
      resizableFieldMaxHeight,
    );
  }

  void _drag(DragUpdateDetails details) {
    setState(() {
      _height = (_height + details.delta.dy).clamp(
        resizableFieldMinHeight,
        resizableFieldMaxHeight,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Stack(
      children: [
        SizedBox(
          height: _height,
          child: TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType ?? TextInputType.multiline,
            inputFormatters: widget.inputFormatters,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(color: c.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              labelText: widget.label,
              alignLabelWithHint: true,
              contentPadding: const EdgeInsets.fromLTRB(
                Insets.md,
                Insets.md,
                Insets.xl,
                Insets.md,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: Insets.md),
                        Icon(widget.prefixIcon, color: c.textSecondary),
                      ],
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _drag,
            child: Padding(
              padding: const EdgeInsets.all(Insets.sm),
              child: CustomPaint(
                size: const Size(12, 12),
                painter: _GripPainter(color: c.textHint),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GripPainter extends CustomPainter {
  final Color color;

  const _GripPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final offset = i * 4.0;
      canvas.drawLine(
        Offset(size.width - offset, size.height),
        Offset(size.width, size.height - offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GripPainter oldDelegate) => oldDelegate.color != color;
}
