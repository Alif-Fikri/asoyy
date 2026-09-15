import 'dart:ui';

enum TooltipSide { above, below, center }

class TourPlacement {
  final TooltipSide side;
  final double top;
  final double left;
  final double width;
  final double arrowX;

  const TourPlacement({
    required this.side,
    required this.top,
    required this.left,
    required this.width,
    required this.arrowX,
  });
}

const double tourGap = 16;
const double tourMargin = 16;
const double tourArrowSize = 10;

TooltipSide sideForTarget({
  required Rect target,
  required Size screen,
  required double cardHeight,
}) {
  final spaceBelow = screen.height - target.bottom;
  final spaceAbove = target.top;
  final needed = cardHeight + tourGap + tourArrowSize + tourMargin;

  if (spaceBelow >= needed) return TooltipSide.below;
  if (spaceAbove >= needed) return TooltipSide.above;
  return TooltipSide.center;
}

TourPlacement placeTooltip({
  required Rect target,
  required Size screen,
  required double cardHeight,
}) {
  final width = screen.width - tourMargin * 2;
  final left = tourMargin;
  final side = sideForTarget(
    target: target,
    screen: screen,
    cardHeight: cardHeight,
  );

  final double top;
  switch (side) {
    case TooltipSide.below:
      top = target.bottom + tourGap + tourArrowSize;
    case TooltipSide.above:
      top = target.top - tourGap - tourArrowSize - cardHeight;
    case TooltipSide.center:
      top = (screen.height - cardHeight) / 2;
  }

  final rawArrowX = target.center.dx;
  final arrowX = rawArrowX.clamp(
    left + tourMargin + tourArrowSize,
    left + width - tourMargin - tourArrowSize,
  );

  return TourPlacement(
    side: side,
    top: top.clamp(tourMargin, screen.height - cardHeight - tourMargin),
    left: left,
    width: width,
    arrowX: arrowX.toDouble(),
  );
}

Rect padTarget(Rect target, double padding, Size screen) {
  final padded = Rect.fromLTRB(
    target.left - padding,
    target.top - padding,
    target.right + padding,
    target.bottom + padding,
  );
  return Rect.fromLTRB(
    padded.left.clamp(0.0, screen.width),
    padded.top.clamp(0.0, screen.height),
    padded.right.clamp(0.0, screen.width),
    padded.bottom.clamp(0.0, screen.height),
  );
}
