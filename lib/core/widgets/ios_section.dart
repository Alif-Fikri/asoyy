import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_color_theme.dart';

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
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 24),
    this.dividerIndent = 16,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                header!.toUpperCase(),
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: c.card,
              child: Column(
                children: _interleaveSeparators(children, c.divider),
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                footer!,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
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
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: titleColor ?? c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        if (showChevron) ...[
          const SizedBox(width: 4),
          Icon(CupertinoIcons.chevron_right, size: 18, color: c.textHint),
        ],
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: content),
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
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.6),
    );
  }
}
