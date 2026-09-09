import 'package:flutter/material.dart';
import '../theme/app_color_theme.dart';
import '../theme/design_tokens.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.cardLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: Sizes.iconLg, color: c.textSecondary),
            ),
            const SizedBox(height: Insets.lg),
            Text(
              title,
              style: AppType.title.copyWith(color: c.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Insets.sm),
            Text(
              subtitle,
              style: AppType.caption.copyWith(
                color: c.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Insets.xl),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
