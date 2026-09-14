import 'package:flutter/cupertino.dart';
import '../constants/app_colors.dart';
import '../theme/app_color_theme.dart';
import '../theme/design_tokens.dart';

class ReminderHintBanner extends StatelessWidget {
  final String text;

  const ReminderHintBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: Insets.lg),
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.bell_fill, color: AppColors.primary, size: 16),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Text(
              text,
              style: AppType.caption.copyWith(color: c.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
