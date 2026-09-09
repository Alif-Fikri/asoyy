import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/csv_share.dart';
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
  if (state is! PasswordLoaded || state.all.isEmpty) return;

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

  try {
    final file = await CsvService().exportToFile(state.all);
    if (!context.mounted) return;
    await shareCsvSnackBar(context, file);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.pass_import_error)),
      );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.pass_import_empty)),
    );
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
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        isId
            ? '${passwords.length} password diimport'
            : '${passwords.length} password${passwords.length == 1 ? '' : 's'} imported',
      ),
    ),
  );
}
