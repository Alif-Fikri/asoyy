import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/locale_bloc.dart';
import '../theme/app_color_theme.dart';
import '../theme/theme_cubit.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          icon: Icon(
            isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
            color: context.colors.textSecondary,
            size: 20,
          ),
          onPressed: () => context.read<ThemeCubit>().toggle(),
          tooltip: isDark ? 'Light Mode' : 'Dark Mode',
        );
      },
    );
  }
}

class LanguageToggleChip extends StatelessWidget {
  const LanguageToggleChip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<LocaleBloc, Locale>(
      builder: (context, locale) {
        final isId = locale.languageCode == 'id';
        return GestureDetector(
          onTap: () => context.read<LocaleBloc>().toggle(),
          child: Container(
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
      },
    );
  }
}
