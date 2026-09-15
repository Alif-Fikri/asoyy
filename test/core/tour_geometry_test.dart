import 'dart:ui';

import 'package:asoyy/core/tour/tour_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const screen = Size(400, 800);
  const cardHeight = 160.0;

  group('sideForTarget', () {
    test('sits below a target near the top', () {
      expect(
        sideForTarget(
          target: const Rect.fromLTWH(20, 60, 360, 60),
          screen: screen,
          cardHeight: cardHeight,
        ),
        TooltipSide.below,
      );
    });

    test('sits above a target near the bottom', () {
      expect(
        sideForTarget(
          target: const Rect.fromLTWH(20, 700, 360, 60),
          screen: screen,
          cardHeight: cardHeight,
        ),
        TooltipSide.above,
      );
    });

    test('falls back to the middle when neither side fits', () {
      expect(
        sideForTarget(
          target: const Rect.fromLTWH(0, 100, 400, 600),
          screen: screen,
          cardHeight: cardHeight,
        ),
        TooltipSide.center,
      );
    });
  });

  group('placeTooltip', () {
    test('never runs off the top or bottom of the screen', () {
      for (final top in [0.0, 10.0, 400.0, 760.0, 790.0]) {
        final placement = placeTooltip(
          target: Rect.fromLTWH(20, top, 360, 40),
          screen: screen,
          cardHeight: cardHeight,
        );
        expect(placement.top, greaterThanOrEqualTo(tourMargin));
        expect(
          placement.top + cardHeight,
          lessThanOrEqualTo(screen.height - tourMargin),
          reason: 'target top $top',
        );
      }
    });

    test('spans the screen width inside the margins', () {
      final placement = placeTooltip(
        target: const Rect.fromLTWH(20, 100, 60, 40),
        screen: screen,
        cardHeight: cardHeight,
      );
      expect(placement.left, tourMargin);
      expect(placement.width, screen.width - tourMargin * 2);
    });

    test('the arrow points at the middle of the target', () {
      final placement = placeTooltip(
        target: const Rect.fromLTWH(100, 100, 100, 40),
        screen: screen,
        cardHeight: cardHeight,
      );
      expect(placement.arrowX, 150);
    });

    test('the arrow stays inside the card for a target at the edge', () {
      final left = placeTooltip(
        target: const Rect.fromLTWH(0, 100, 20, 40),
        screen: screen,
        cardHeight: cardHeight,
      );
      expect(left.arrowX, greaterThan(tourMargin));

      final right = placeTooltip(
        target: const Rect.fromLTWH(380, 100, 20, 40),
        screen: screen,
        cardHeight: cardHeight,
      );
      expect(right.arrowX, lessThan(screen.width - tourMargin));
    });

    test('leaves a gap between the card and the target', () {
      final below = placeTooltip(
        target: const Rect.fromLTWH(20, 60, 360, 60),
        screen: screen,
        cardHeight: cardHeight,
      );
      expect(below.side, TooltipSide.below);
      expect(below.top, greaterThan(120));
    });
  });

  group('padTarget', () {
    test('grows the highlight evenly', () {
      final padded = padTarget(
        const Rect.fromLTWH(100, 100, 100, 50),
        8,
        screen,
      );
      expect(padded, const Rect.fromLTRB(92, 92, 208, 158));
    });

    test('never spills outside the screen', () {
      final padded = padTarget(
        const Rect.fromLTWH(0, 0, 400, 800),
        12,
        screen,
      );
      expect(padded.left, 0);
      expect(padded.top, 0);
      expect(padded.right, screen.width);
      expect(padded.bottom, screen.height);
    });
  });
}
