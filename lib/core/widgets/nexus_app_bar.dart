import 'package:flutter/material.dart';
import '../theme/app_color_theme.dart';

class NexusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;
  final Widget? leading;

  const NexusAppBar({
    super.key,
    required this.title,
    this.extraActions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppBar(
      scrolledUnderElevation: 0,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 1,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      leading: leading,
      actions: extraActions,
    );
  }
}
