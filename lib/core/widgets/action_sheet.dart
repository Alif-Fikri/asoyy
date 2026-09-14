import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_color_theme.dart';
import '../theme/design_tokens.dart';

class SheetAction<T> {
  final T value;
  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;

  const SheetAction({
    required this.value,
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
  });
}

Future<T?> showActionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetAction<T>> actions,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet<T>(title: title, actions: actions),
    );

class _ActionSheet<T> extends StatelessWidget {
  final String title;
  final List<SheetAction<T>> actions;

  const _ActionSheet({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        Insets.xl,
        Insets.lg,
        Insets.xl,
        MediaQuery.of(context).padding.bottom + Insets.xl,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Insets.xl),
          Text(
            title,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Insets.lg),
          for (final action in actions) ...[
            _ActionTile<T>(action: action),
            if (action != actions.last) const SizedBox(height: Insets.md),
          ],
        ],
      ),
    );
  }
}

class _ActionTile<T> extends StatelessWidget {
  final SheetAction<T> action;

  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        onTap: () => Navigator.pop(context, action.value),
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: Row(
            children: [
              Container(
                width: Sizes.menuIcon,
                height: Sizes.menuIcon,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Icon(action.icon, color: action.color, size: 20),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: AppType.bodyStrong.copyWith(color: c.textPrimary),
                    ),
                    if (action.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        action.subtitle!,
                        style: AppType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, size: 18, color: c.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
