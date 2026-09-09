import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_color_theme.dart';

const _userNameKey = 'user_name';
const _defaultUserName = 'Pengguna';

String readUserName() =>
    Hive.box(AppConstants.settingsBox)
        .get(_userNameKey, defaultValue: _defaultUserName) as String;

Future<void> writeUserName(String name) =>
    Hive.box(AppConstants.settingsBox).put(_userNameKey, name);

Future<String?> showEditNameDialog(BuildContext context) async {
  final s = context.strings;
  final c = context.colors;
  final ctrl = TextEditingController(text: readUserName());

  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        s.edit_name,
        style: TextStyle(
          color: c.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: TextField(
        controller: ctrl,
        style: TextStyle(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: s.enter_name,
          hintStyle: TextStyle(color: c.textHint),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(s.cancel, style: TextStyle(color: c.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: Text(
            s.save,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  if (name == null || name.isEmpty) return null;
  await writeUserName(name);
  return name;
}
