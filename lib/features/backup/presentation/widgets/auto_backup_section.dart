import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/auto_backup_schedule.dart';
import '../../services/auto_backup_runner.dart';
import '../../services/auto_backup_settings.dart';
import '../../../password/data/auth_config_repository.dart';
import '../../../password/presentation/pages/password_auth_gate.dart';

String frequencyLabel(BackupFrequency frequency, AppStrings s) {
  switch (frequency) {
    case BackupFrequency.daily:
      return s.auto_backup_daily;
    case BackupFrequency.weekly:
      return s.auto_backup_weekly;
    case BackupFrequency.monthly:
      return s.auto_backup_monthly;
  }
}

class AutoBackupSection extends StatefulWidget {
  final Future<String?> Function() askPassphrase;

  const AutoBackupSection({super.key, required this.askPassphrase});

  @override
  State<AutoBackupSection> createState() => _AutoBackupSectionState();
}

class _AutoBackupSectionState extends State<AutoBackupSection> {
  final _settings = AutoBackupSettings();
  bool _hasPassphrase = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _refreshPassphrase();
  }

  Future<void> _refreshPassphrase() async {
    final stored = await _settings.readPassphrase();
    if (!mounted) return;
    setState(() => _hasPassphrase = stored != null && stored.isNotEmpty);
  }

  Future<void> _toggle(bool value) async {
    if (value && (_settings.folder == null || !_hasPassphrase)) {
      AppToast.show(context, context.strings.auto_backup_incomplete);
      return;
    }
    await _settings.setEnabled(value);
    if (mounted) setState(() {});
    if (value) await _runNow();
  }

  Future<void> _pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null || !mounted) return;
    await _settings.setFolder(path);
    if (mounted) setState(() {});
  }

  Future<void> _showPassphrase() async {
    final s = context.strings;
    final repo = AuthConfigRepository();
    if (repo.isConfigured) {
      final ok = await verifyCurrentAuth(context, repo);
      if (!ok || !mounted) return;
    }

    final stored = await _settings.readPassphrase();
    if (stored == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        return AlertDialog(
          backgroundColor: c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            s.auto_backup_view_title,
            style: TextStyle(color: c.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                stored,
                style: AppType.title.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: Insets.md),
              Text(
                s.auto_backup_view_hint,
                style: AppType.caption.copyWith(
                  color: c.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.close),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: stored));
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) AppToast.show(context, s.auto_backup_copied);
              },
              child: Text(s.copy),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setPassphrase() async {
    final passphrase = await widget.askPassphrase();
    if (passphrase == null || !mounted) return;
    await _settings.writePassphrase(passphrase);
    await _refreshPassphrase();
    if (mounted) {
      AppToast.show(context, context.strings.auto_backup_saved_warning);
    }
  }

  Future<void> _pickFrequency() async {
    final s = context.strings;
    final picked = await showModalBottomSheet<BackupFrequency>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = ctx.colors;
        return Container(
          padding: EdgeInsets.fromLTRB(Insets.xl, Insets.lg, Insets.xl,
              MediaQuery.of(ctx).padding.bottom + Insets.xl),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.auto_backup_frequency,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Insets.md),
              for (final f in BackupFrequency.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    frequencyLabel(f, s),
                    style: TextStyle(color: c.textPrimary),
                  ),
                  trailing: f == _settings.frequency
                      ? const Icon(CupertinoIcons.check_mark,
                          color: AppColors.backupColor, size: 18)
                      : null,
                  onTap: () => Navigator.pop(ctx, f),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    await _settings.setFrequency(picked);
    if (mounted) setState(() {});
  }

  Future<void> _runNow() async {
    setState(() => _running = true);
    final result = await AutoBackupRunner(settings: _settings).runIfDue();
    if (!mounted) return;
    setState(() => _running = false);

    final s = context.strings;
    if (result.ran) {
      AppToast.show(context, s.auto_backup_done);
    } else if (result.error != null) {
      AppToast.show(context, s.auto_backup_failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final lastRun = _settings.lastRun;
    final folder = _settings.folder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.auto_backup_title.toUpperCase(),
          style: AppType.label.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: Insets.sm),
        Text(
          s.auto_backup_subtitle,
          style: AppType.caption.copyWith(color: c.textSecondary, height: 1.4),
        ),
        const SizedBox(height: Insets.md),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: _settings.enabled,
                onChanged: _running ? null : _toggle,
                title: Text(
                  s.auto_backup_enable,
                  style: AppType.body.copyWith(color: c.textPrimary),
                ),
              ),
              Divider(height: 1, color: c.divider),
              _Row(
                label: s.auto_backup_frequency,
                value: frequencyLabel(_settings.frequency, s),
                onTap: _pickFrequency,
              ),
              Divider(height: 1, color: c.divider),
              _Row(
                label: s.auto_backup_folder,
                value: folder == null
                    ? s.auto_backup_folder_none
                    : folder.split('/').last,
                onTap: _pickFolder,
                highlight: folder == null,
              ),
              Divider(height: 1, color: c.divider),
              _Row(
                label: s.auto_backup_passphrase,
                value: _hasPassphrase
                    ? s.auto_backup_change_passphrase
                    : s.auto_backup_passphrase_none,
                onTap: _setPassphrase,
                highlight: !_hasPassphrase,
              ),
              if (_hasPassphrase) ...[
                Divider(height: 1, color: c.divider),
                _Row(
                  label: s.auto_backup_view_passphrase,
                  value: '',
                  onTap: _showPassphrase,
                ),
              ],
              Divider(height: 1, color: c.divider),
              _Row(
                label: s.auto_backup_last_run,
                value: lastRun == null
                    ? s.auto_backup_never
                    : DateFormat('d MMM yyyy HH:mm').format(lastRun),
                onTap: null,
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.sm),
        Text(
          '${s.auto_backup_kept(keptBackupCount)} · ${s.auto_backup_on_device_warning}',
          style: AppType.caption.copyWith(color: c.textSecondary, height: 1.4),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool highlight;

  const _Row({
    required this.label,
    required this.value,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppType.body.copyWith(color: c.textPrimary),
              ),
            ),
            Text(
              value,
              style: AppType.caption.copyWith(
                color: highlight ? AppColors.expense : c.textSecondary,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: Insets.xs),
              Icon(CupertinoIcons.chevron_right, size: 16, color: c.textHint),
            ],
          ],
        ),
      ),
    );
  }
}
