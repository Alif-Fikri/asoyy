import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/locale_bloc.dart';
import '../theme/app_color_theme.dart';

class NexusAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLanguageToggle;
  final List<Widget>? extraActions;
  final Widget? leading;

  const NexusAppBar({
    super.key,
    required this.title,
    this.showLanguageToggle = false,
    this.extraActions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (extraActions != null) ...extraActions!,
      if (showLanguageToggle) ...[_LangToggle(), const SizedBox(width: 8)],
    ];

    return AppBar(
      scrolledUnderElevation: 0,
      title: Text(title),
      leading: leading,
      actions: actions,
    );
  }
}

class _LangToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isId = context.read<LocaleBloc>().state.languageCode == 'id';
    final c = context.colors;
    return GestureDetector(
      onTap: () => context.read<LocaleBloc>().toggle(),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isId ? '🇮🇩' : '🇺🇸', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              isId ? 'ID' : 'EN',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
