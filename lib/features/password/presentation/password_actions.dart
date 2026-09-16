import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/app_toast.dart';
import '../data/auth_config_repository.dart';
import '../services/csv_service.dart';
import 'bloc/password_bloc.dart';
import 'bloc/password_event.dart';
import 'bloc/password_state.dart';
import 'pages/password_auth_gate.dart';

Future<void> changeAuthMethod(
  BuildContext context,
  AuthConfigRepository repo,
) async {
  final ok = await verifyCurrentAuth(context, repo);
  if (!ok || !context.mounted) return;
  await repo.clear();
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => PasswordAuthGate(
        repo: repo,
        onAuthenticated: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
  if (context.mounted && repo.isConfigured) {
    AppToast.show(context, context.strings.auth_method_updated);
  }
}

Future<void> exportPasswordsCsv(
  BuildContext context,
  AuthConfigRepository repo,
) async {
  final s = context.strings;
  final isId = context.currentLocale.languageCode == 'id';
  final bloc = context.read<PasswordBloc>();

  final ok = await verifyCurrentAuth(context, repo);
  if (!ok || !context.mounted) return;

  final state = bloc.state;
  if (state is! PasswordLoaded || state.all.isEmpty) {
    if (context.mounted) AppToast.show(context, s.pass_export_empty);
    return;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.pass_export),
      content: Text(s.pass_export_warning),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(isId ? 'Batal' : 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Export'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;

  final screenSize = MediaQuery.of(context).size;
  File? file;
  try {
    await purgeStalePasswordExports();
    file = await CsvService().exportToFile(state.all);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      sharePositionOrigin: Rect.fromLTWH(
        0,
        screenSize.height - 100,
        screenSize.width,
        100,
      ),
    );
  } catch (_) {
    if (context.mounted) AppToast.show(context, s.pass_import_error);
  } finally {
    if (file != null) {
      final toDelete = file;
      unawaited(Future.delayed(const Duration(seconds: 5), () async {
        if (await toDelete.exists()) {
          try {
            await toDelete.delete();
          } catch (_) {}
        }
      }));
    }
  }
}

Future<void> importPasswordsCsv(
  BuildContext context,
  AuthConfigRepository repo,
) async {
  final s = context.strings;
  final isId = context.currentLocale.languageCode == 'id';
  final bloc = context.read<PasswordBloc>();

  final ok = await verifyCurrentAuth(context, repo);
  if (!ok || !context.mounted) return;

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    withData: true,
  );
  if (result == null || result.files.single.bytes == null) return;
  if (!context.mounted) return;

  final passwords = CsvService().importFromBytes(result.files.single.bytes!);

  if (passwords.isEmpty) {
    AppToast.show(context, s.pass_import_empty);
    return;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.pass_import_title),
      content: Text(
        isId
            ? 'Ditemukan ${passwords.length} password. Import semua?'
            : 'Found ${passwords.length} password${passwords.length == 1 ? '' : 's'}. Import all?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(isId ? 'Batal' : 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Import'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;

  bloc.add(ImportPasswordsRequested(passwords));
  AppToast.show(
    context,
    isId
        ? '${passwords.length} password diimport'
        : '${passwords.length} password${passwords.length == 1 ? '' : 's'} imported',
  );
}
