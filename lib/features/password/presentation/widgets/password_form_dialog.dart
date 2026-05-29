import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/password_entity.dart';

class PasswordFormDialog extends StatefulWidget {
  final PasswordEntity? existing;
  final void Function(PasswordEntity) onSave;

  const PasswordFormDialog({super.key, this.existing, required this.onSave});

  @override
  State<PasswordFormDialog> createState() => _PasswordFormDialogState();
}

class _PasswordFormDialogState extends State<PasswordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _webCtrl;
  late final TextEditingController _notesCtrl;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _userCtrl = TextEditingController(text: e?.username ?? '');
    _passCtrl = TextEditingController(text: e?.password ?? '');
    _webCtrl = TextEditingController(text: e?.website ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _userCtrl, _passCtrl, _webCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(PasswordEntity(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      website: _webCtrl.text.trim().isEmpty ? null : _webCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.existing == null ? s.pass_add : s.pass_edit,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: s.pass_app_name,
                controller: _titleCtrl,
                prefixIcon: CupertinoIcons.square_grid_2x2,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.required_field : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: s.pass_username,
                controller: _userCtrl,
                prefixIcon: CupertinoIcons.person,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.required_field : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: s.pass_password,
                controller: _passCtrl,
                prefixIcon: CupertinoIcons.lock,
                obscureText: _obscure,
                validator: (v) => (v == null || v.isEmpty) ? s.required_field : null,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: '${s.pass_website} (${s.optional})',
                controller: _webCtrl,
                prefixIcon: CupertinoIcons.globe,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: '${s.pass_notes} (${s.optional})',
                controller: _notesCtrl,
                prefixIcon: CupertinoIcons.doc_text,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: widget.existing == null ? s.pass_save : s.pass_update,
                onTap: _submit,
                width: double.infinity,
                color: AppColors.passwordColor,
                icon: CupertinoIcons.tray_arrow_down,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
