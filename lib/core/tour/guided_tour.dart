import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_color_theme.dart';
import '../theme/design_tokens.dart';
import 'tour_geometry.dart';
import 'tour_step.dart';

const double tourCardHeight = 170;

Future<void> showGuidedTour(
  BuildContext context, {
  required List<TourStep> steps,
  Future<void> Function(int index)? onBeforeStep,
}) async {
  if (steps.isEmpty) return;
  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) => _TourOverlay(
        steps: steps,
        onBeforeStep: onBeforeStep,
      ),
    ),
  );
}

class _TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final Future<void> Function(int index)? onBeforeStep;

  const _TourOverlay({required this.steps, this.onBeforeStep});

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  int _index = 0;
  Rect? _target;
  bool _preparing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    setState(() => _preparing = true);
    await widget.onBeforeStep?.call(_index);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() {
      _target = _rectFor(widget.steps[_index]);
      _preparing = false;
    });
  }

  Rect? _rectFor(TourStep step) {
    final key = step.targetKey;
    if (key == null) return null;
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
    _prepare();
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
    _prepare();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final step = widget.steps[_index];
    final target = _target;

    final placement = target == null
        ? TourPlacement(
            side: TooltipSide.center,
            top: (screen.height - tourCardHeight) / 2,
            left: tourMargin,
            width: screen.width - tourMargin * 2,
            arrowX: screen.width / 2,
          )
        : placeTooltip(
            target: padTarget(target, Insets.sm, screen),
            screen: screen,
            cardHeight: tourCardHeight,
          );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                target: target == null
                    ? null
                    : padTarget(target, Insets.sm, screen),
                radius: step.highlightRadius,
              ),
            ),
          ),
          if (!_preparing)
            Positioned(
              top: placement.top,
              left: placement.left,
              width: placement.width,
              child: _TourCard(
                step: step,
                index: _index,
                total: widget.steps.length,
                placement: placement,
                onNext: _next,
                onBack: _index == 0 ? null : _back,
                onSkip: () => Navigator.of(context).pop(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? target;
  final double radius;

  const _SpotlightPainter({required this.target, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = const Color(0xE0000000);
    final full = Rect.fromLTWH(0, 0, size.width, size.height);

    if (target == null) {
      canvas.drawRect(full, overlay);
      return;
    }

    final hole = RRect.fromRectAndRadius(target!, Radius.circular(radius));
    canvas.saveLayer(full, Paint());
    canvas.drawRect(full, overlay);
    canvas.drawRRect(hole, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.target != target || oldDelegate.radius != radius;
}

class _TourCard extends StatelessWidget {
  final TourStep step;
  final int index;
  final int total;
  final TourPlacement placement;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  const _TourCard({
    required this.step,
    required this.index,
    required this.total,
    required this.placement,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final isLast = index == total - 1;

    final card = Container(
      height: tourCardHeight,
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}/$total',
            style: AppType.label.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            step.title,
            style: AppType.title.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: Insets.xs),
          Expanded(
            child: Text(
              step.body,
              style: AppType.caption.copyWith(
                color: c.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: onSkip,
                child: Text(
                  s.tour_skip,
                  style: AppType.caption.copyWith(color: c.textSecondary),
                ),
              ),
              const Spacer(),
              if (onBack != null)
                TextButton(
                  onPressed: onBack,
                  child: Text(s.tour_back),
                ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                onPressed: onNext,
                child: Text(isLast ? s.tour_done : s.tour_next),
              ),
            ],
          ),
        ],
      ),
    );

    if (placement.side == TooltipSide.center) return card;

    final arrow = CustomPaint(
      size: const Size(tourArrowSize * 2, tourArrowSize),
      painter: _ArrowPainter(
        color: c.surface,
        border: AppColors.primary.withValues(alpha: 0.4),
        pointsUp: placement.side == TooltipSide.below,
      ),
    );

    final arrowRow = Row(
      children: [
        SizedBox(width: placement.arrowX - placement.left - tourArrowSize),
        arrow,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: placement.side == TooltipSide.below
          ? [arrowRow, card]
          : [card, arrowRow],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final Color border;
  final bool pointsUp;

  const _ArrowPainter({
    required this.color,
    required this.border,
    required this.pointsUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointsUp != pointsUp;
}
