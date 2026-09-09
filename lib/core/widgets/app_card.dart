import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_color_theme.dart';
import '../theme/design_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.radius = Radii.lg,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(Insets.lg),
          decoration: BoxDecoration(
            color: gradient == null ? (color ?? c.card) : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? c.border, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.padding,
    this.radius = Radii.lg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      radius: radius,
      onTap: onTap,
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: AppColors.transparent,
      child: child,
    );
  }
}
