import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_color_theme.dart';
import '../theme/design_tokens.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  const AppChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
    this.icon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = color ?? AppColors.primary;
    final fg = isSelected ? accent : c.textSecondary;

    return Material(
      color: isSelected ? accent.withValues(alpha: 0.12) : c.card,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: Insets.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: isSelected ? accent : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: Sizes.iconSm, color: fg),
                const SizedBox(width: Insets.xs + 2),
              ],
              Text(
                label,
                style: AppType.caption.copyWith(
                  color: fg,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: Insets.xs),
                Icon(trailingIcon, size: Sizes.iconSm, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
