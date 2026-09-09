import 'package:flutter/material.dart';

abstract class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 100;
}

abstract class Sizes {
  static const double touchTarget = 44;
  static const double rowMinHeight = 56;
  static const double fieldHeight = 48;
  static const double icon = 20;
  static const double iconSm = 16;
  static const double iconLg = 24;
  static const double iconTile = 36;
  static const double menuIcon = 40;
}

abstract class AppType {
  static const label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );
  static const caption = TextStyle(fontSize: 13);
  static const body = TextStyle(fontSize: 15);
  static const bodyStrong = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const title = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
}
