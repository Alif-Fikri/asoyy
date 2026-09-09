import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_color_theme.dart';
import '../theme/design_tokens.dart';

class IosSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final EdgeInsets margin;
  final double dividerIndent;

  const IosSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.margin = const EdgeInsets.fromLTRB(
      Insets.lg,
      0,
      Insets.lg,
      Insets.xl,
    ),
    this.dividerIndent = Insets.lg,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.xs,
                0,
                Insets.xs,
                Insets.sm,
              ),
              child: Text(
                header!.toUpperCase(),
                style: AppType.label.copyWith(color: c.textSecondary),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.lg),
            child: Container(
              decoration: BoxDecoration(
                color: c.card,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(Radii.lg),
              ),
              child: Column(
                children: _interleaveSeparators(children, c.divider),
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.xs,
                Insets.sm,
                Insets.xs,
                0,
              ),
              child: Text(
                footer!,
                style: AppType.caption.copyWith(
                  color: c.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _interleaveSeparators(List<Widget> rows, Color color) {
    if (rows.length <= 1) return rows;
    final result = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i != rows.length - 1) {
        result.add(
          Padding(
            padding: EdgeInsets.only(left: dividerIndent),
            child: Container(height: 0.5, color: color),
          ),
        );
      }
    }
    return result;
  }
}

class IosRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final EdgeInsets padding;
  final bool showChevron;

  const IosRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Insets.lg,
      vertical: Insets.md,
    ),
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: Insets.md)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppType.body.copyWith(
                  color: titleColor ?? c.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppType.caption.copyWith(color: c.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: Insets.md), trailing!],
        if (showChevron) ...[
          const SizedBox(width: Insets.xs),
          Icon(
            CupertinoIcons.chevron_right,
            size: Insets.lg,
            color: c.textHint,
          ),
        ],
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.rowMinHeight),
          child: Padding(padding: padding, child: content),
        ),
      ),
    );
  }
}

class IosIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IosIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = Sizes.iconTile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.sm + 2),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}
