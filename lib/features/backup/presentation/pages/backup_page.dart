import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../services/backup_service.dart';
import '../widgets/auto_backup_section.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final _service = BackupService();
  bool _busy = false;

  Future<String?> _askPassphrase({required bool confirmRequired}) {
    final s = context.strings;
    final ctrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final c = dialogContext.colors;
        return AlertDialog(
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            s.backup_passphrase,
            style: TextStyle(color: c.textPrimary),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: ctrl,
                    obscureText: true,
                    autofocus: true,
                    style: TextStyle(color: c.textPrimary),
                    decoration: InputDecoration(labelText: s.backup_passphrase),
                    validator:
                        (v) =>
                            (v == null || v.length < 6)
                                ? s.backup_passphrase_too_short
                                : null,
                  ),
                  if (confirmRequired) ...[
                    const SizedBox(height: Insets.sm),
                    TextFormField(
                      controller: confirmCtrl,
                      obscureText: true,
                      style: TextStyle(color: c.textPrimary),
                      decoration: InputDecoration(
                        labelText: s.backup_passphrase_confirm,
                      ),
                      validator:
                          (v) =>
                              (v != ctrl.text)
                                  ? s.backup_passphrase_mismatch
                                  : null,
                    ),
                  ],
                  if (confirmRequired) ...[
                    const SizedBox(height: Insets.md),
                    Text(
                      s.backup_passphrase_hint,
                      style: AppType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, ctrl.text);
              },
              child: Text(s.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _backupNow() async {
    final passphrase = await _askPassphrase(confirmRequired: true);
    if (passphrase == null) return;

    setState(() => _busy = true);
    try {
      final file = await _service.createBackup(passphrase);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
      if (mounted) AppToast.show(context, context.strings.backup_success);
    } catch (e) {
      if (mounted)
        AppToast.show(context, '${context.strings.backup_restore_failed}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final s = context.strings;
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(type: FileType.any);
    } catch (_) {
      if (mounted) AppToast.show(context, s.backup_restore_failed);
      return;
    }
    final path = result?.files.single.path;
    if (path == null) return;

    final passphrase = await _askPassphrase(confirmRequired: false);
    if (passphrase == null) return;

    setState(() => _busy = true);
    try {
      await _service.restoreBackup(File(path), passphrase);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final c = dialogContext.colors;
          return AlertDialog(
            backgroundColor: c.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              s.backup_restore_success,
              style: TextStyle(color: c.textPrimary),
            ),
            content: Text(
              s.backup_restart_required,
              style: TextStyle(color: c.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: Text(s.backup_close_app),
              ),
            ],
          );
        },
      );
    } on BackupException catch (e) {
      if (mounted) AppToast.show(context, e.message);
    } catch (_) {
      if (mounted) AppToast.show(context, s.backup_restore_failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.backup_title),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Insets.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(Insets.md),
              decoration: BoxDecoration(
                color: AppColors.backupColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(
                  color: AppColors.backupColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    color: AppColors.backupColor,
                    size: 18,
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Text(
                      s.backup_warning_hint,
                      style: AppType.caption.copyWith(
                        color: c.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.xl),
            AppButton(
              label: s.backup_now,
              onTap: _busy ? null : _backupNow,
              isLoading: _busy,
              width: double.infinity,
              color: AppColors.backupColor,
              icon: CupertinoIcons.arrow_up_doc,
            ),
            const SizedBox(height: Insets.md),
            AppButton(
              label: s.backup_restore,
              onTap: _busy ? null : _restore,
              isLoading: _busy,
              isOutlined: true,
              width: double.infinity,
              color: AppColors.backupColor,
              icon: CupertinoIcons.arrow_down_doc,
            ),
            const SizedBox(height: Insets.xxl),
            AutoBackupSection(
              askPassphrase: () => _askPassphrase(confirmRequired: true),
            ),
          ],
        ),
      ),
    );
  }
}
