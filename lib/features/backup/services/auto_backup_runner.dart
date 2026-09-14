import 'dart:io';

import '../domain/auto_backup_schedule.dart';
import 'auto_backup_settings.dart';
import 'backup_service.dart';

const String autoBackupPrefix = 'beres-auto-';

class AutoBackupResult {
  final bool ran;
  final String? path;
  final String? error;

  const AutoBackupResult({required this.ran, this.path, this.error});
}

class AutoBackupRunner {
  final BackupService service;
  final AutoBackupSettings settings;

  AutoBackupRunner({BackupService? service, AutoBackupSettings? settings})
      : service = service ?? BackupService(),
        settings = settings ?? AutoBackupSettings();

  Future<AutoBackupResult> runIfDue({DateTime? now}) async {
    final moment = now ?? DateTime.now();

    if (!isBackupDue(
      enabled: settings.enabled,
      frequency: settings.frequency,
      lastRun: settings.lastRun,
      now: moment,
    )) {
      return const AutoBackupResult(ran: false);
    }

    final folder = settings.folder;
    final passphrase = await settings.readPassphrase();
    if (folder == null || passphrase == null || passphrase.isEmpty) {
      await settings.setLastError('not-configured');
      return const AutoBackupResult(ran: false, error: 'not-configured');
    }

    try {
      final source = await service.createBackup(passphrase);
      final target = File(
        '$folder/$autoBackupPrefix${_stamp(moment)}.bkp',
      );
      await target.writeAsBytes(await source.readAsBytes(), flush: true);
      await pruneOldBackups(folder);

      await settings.setLastRun(moment);
      await settings.setLastError(null);
      return AutoBackupResult(ran: true, path: target.path);
    } catch (e) {
      await settings.setLastError(e.toString());
      return AutoBackupResult(ran: false, error: e.toString());
    }
  }

  Future<void> pruneOldBackups(String folder) async {
    final dir = Directory(folder);
    if (!dir.existsSync()) return;

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith(autoBackupPrefix))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    for (final path in backupsToDelete(files.map((f) => f.path).toList())) {
      try {
        await File(path).delete();
      } catch (_) {
        continue;
      }
    }
  }

  static String _stamp(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${at.year}${two(at.month)}${two(at.day)}-${two(at.hour)}${two(at.minute)}';
  }
}
