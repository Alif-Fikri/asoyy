import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/app_color_theme.dart';
import '../theme/design_tokens.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;
  final bool isOutlined;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.textColor,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDisabled = onTap == null && !isLoading;

    final accent = color ?? AppColors.primary;
    final bg = isDisabled ? c.cardLight : accent;
    final fg = isDisabled
        ? c.textHint
        : (textColor ?? (isOutlined ? accent : Colors.white));

    return SizedBox(
      width: width,
      child: Material(
        color: isOutlined ? AppColors.transparent : bg,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: Sizes.fieldHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.xl,
              vertical: Insets.md,
            ),
            decoration: isOutlined
                ? BoxDecoration(
                    border: Border.all(
                      color: isDisabled ? c.border : accent,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(Radii.md),
                  )
                : null,
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: Sizes.icon,
                      height: Sizes.icon,
                      child: CircularProgressIndicator(
                        color: fg,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fg, size: 18),
                        const SizedBox(width: Insets.sm),
                      ],
                      Text(
                        label,
                        style: AppType.body.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
