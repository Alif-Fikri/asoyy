import 'package:flutter/widgets.dart';

class TourStep {
  final GlobalKey? targetKey;
  final String title;
  final String body;
  final double highlightRadius;

  const TourStep({
    this.targetKey,
    required this.title,
    required this.body,
    this.highlightRadius = 16,
  });

  bool get isIntro => targetKey == null;
}
