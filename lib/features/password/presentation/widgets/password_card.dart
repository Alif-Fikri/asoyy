import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../domain/entities/password_entity.dart';

class PasswordCard extends StatefulWidget {
  final PasswordEntity password;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PasswordCard({
    super.key,
    required this.password,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard> {
  bool _revealed = false;

  void _copy(String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final p = widget.password;
    final initial = p.title.isNotEmpty ? p.title[0].toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _revealed = !_revealed),
        onLongPress: () async {
          final confirmed = await showDeleteConfirm(context);
          if (confirmed) widget.onDelete();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.passwordColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.passwordColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _revealed
                          ? p.password
                          : (p.username.isNotEmpty ? p.username : '••••••••'),
                      style: TextStyle(
                        color:
                            _revealed ? AppColors.passwordColor : c.textSecondary,
                        fontSize: 13,
                        letterSpacing: _revealed ? 0 : 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: c.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                icon: Icon(CupertinoIcons.ellipsis, color: c.textHint, size: 20),
                onSelected: (v) async {
                  if (v == 'edit') {
                    widget.onEdit();
                  } else if (v == 'copy_user') {
                    _copy(p.username, s.pass_username_copied);
                  } else if (v == 'copy_pass') {
                    _copy(p.password, s.pass_password_copied);
                  } else if (v == 'delete') {
                    final confirmed = await showDeleteConfirm(context);
                    if (confirmed) widget.onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'copy_user',
                    child: _menuItem(c, CupertinoIcons.person, s.pass_copy_user),
                  ),
                  PopupMenuItem(
                    value: 'copy_pass',
                    child:
                        _menuItem(c, CupertinoIcons.lock, s.pass_copy_pass),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: _menuItem(c, CupertinoIcons.pencil, s.edit),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.trash,
                          size: 16,
                          color: AppColors.alarmColor,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          s.delete,
                          style: const TextStyle(
                            color: AppColors.alarmColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(AppColorTheme c, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: c.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: c.textPrimary, fontSize: 14)),
      ],
    );
  }
}
