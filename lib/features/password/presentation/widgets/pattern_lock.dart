import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_color_theme.dart';

class PatternLock extends StatefulWidget {
  final void Function(String pattern) onCompleted;
  final String? errorText;
  final int resetToken;
  final int minDots;

  const PatternLock({
    super.key,
    required this.onCompleted,
    this.errorText,
    this.resetToken = 0,
    this.minDots = 4,
  });

  @override
  State<PatternLock> createState() => _PatternLockState();
}

class _PatternLockState extends State<PatternLock> {
  final List<int> _sequence = [];
  Offset? _currentDragPos;
  final GlobalKey _gridKey = GlobalKey();

  static const _gridSize = 3;
  static const _gridCount = _gridSize * _gridSize;

  @override
  void didUpdateWidget(covariant PatternLock old) {
    super.didUpdateWidget(old);
    if (old.resetToken != widget.resetToken) {
      setState(() {
        _sequence.clear();
        _currentDragPos = null;
      });
    }
  }

  void _onPanStart(DragStartDetails d) {
    _handleTouch(d.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _handleTouch(d.localPosition);
    setState(() => _currentDragPos = d.localPosition);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_sequence.length >= widget.minDots) {
      widget.onCompleted(_sequence.join(','));
    }
    setState(() => _currentDragPos = null);
  }

  void _handleTouch(Offset pos) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final cellW = size.width / _gridSize;
    final cellH = size.height / _gridSize;

    for (int i = 0; i < _gridCount; i++) {
      if (_sequence.contains(i)) continue;
      final row = i ~/ _gridSize;
      final col = i % _gridSize;
      final center = Offset(cellW * (col + 0.5), cellH * (row + 0.5));
      if ((pos - center).distance < cellW * 0.32) {
        HapticFeedback.selectionClick();
        setState(() => _sequence.add(i));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              key: _gridKey,
              painter: _PatternPainter(
                sequence: _sequence,
                currentDragPos: _currentDragPos,
                dotColor: context.colors.border,
                dotActiveColor: AppColors.primary,
                lineColor: AppColors.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
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
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<int> sequence;
  final Offset? currentDragPos;
  final Color dotColor;
  final Color dotActiveColor;
  final Color lineColor;

  _PatternPainter({
    required this.sequence,
    required this.currentDragPos,
    required this.dotColor,
    required this.dotActiveColor,
    required this.lineColor,
  });

  static const _gridSize = 3;

  Offset _dotCenter(int index, Size size) {
    final cellW = size.width / _gridSize;
    final cellH = size.height / _gridSize;
    final row = index ~/ _gridSize;
    final col = index % _gridSize;
    return Offset(cellW * (col + 0.5), cellH * (row + 0.5));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / _gridSize;
    final outerRadius = cellW * 0.16;
    final innerRadius = cellW * 0.06;

    if (sequence.length > 1) {
      final linePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.7)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < sequence.length - 1; i++) {
        canvas.drawLine(
          _dotCenter(sequence[i], size),
          _dotCenter(sequence[i + 1], size),
          linePaint,
        );
      }

      if (currentDragPos != null) {
        canvas.drawLine(
          _dotCenter(sequence.last, size),
          currentDragPos!,
          linePaint,
        );
      }
    } else if (sequence.length == 1 && currentDragPos != null) {
      canvas.drawLine(
        _dotCenter(sequence.first, size),
        currentDragPos!,
        Paint()
          ..color = lineColor.withValues(alpha: 0.7)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int i = 0; i < _gridSize * _gridSize; i++) {
      final isActive = sequence.contains(i);
      final center = _dotCenter(i, size);

      canvas.drawCircle(
        center,
        outerRadius,
        Paint()
          ..color = (isActive ? dotActiveColor : dotColor)
              .withValues(alpha: isActive ? 0.25 : 1),
      );

      canvas.drawCircle(
        center,
        innerRadius,
        Paint()..color = isActive ? dotActiveColor : dotColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) =>
      old.sequence != sequence || old.currentDragPos != currentDragPos;
}
