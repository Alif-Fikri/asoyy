import 'dart:io';

import 'package:asoyy/features/backup/domain/auto_backup_schedule.dart';
import 'package:asoyy/features/backup/services/auto_backup_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('auto_backup');
  });

  tearDown(() async => dir.delete(recursive: true));

  File make(String name) {
    final file = File('${dir.path}/$name')..createSync();
    file.writeAsStringSync(name);
    return file;
  }

  List<String> remaining() => dir
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .toList()
    ..sort();

  test('keeps the newest backups and deletes the rest', () async {
    for (var day = 1; day <= keptBackupCount + 3; day++) {
      make('${autoBackupPrefix}202609${day.toString().padLeft(2, '0')}-1200.bkp');
    }

    await AutoBackupRunner().pruneOldBackups(dir.path);

    final left = remaining();
    expect(left, hasLength(keptBackupCount));
    expect(left.last, contains('20260908'));
    expect(left.first, contains('20260904'));
  });

  test('never touches files it did not write', () async {
    make('${autoBackupPrefix}20260901-1200.bkp');
    make('beres-backup-manual.bkp');
    make('catatan.txt');
    for (var i = 0; i < keptBackupCount + 2; i++) {
      make('${autoBackupPrefix}20260$i${i}0$i-1200.bkp');
    }

    await AutoBackupRunner().pruneOldBackups(dir.path);

    expect(remaining(), contains('beres-backup-manual.bkp'));
    expect(remaining(), contains('catatan.txt'));
  });

  test('does nothing when there is little to prune', () async {
    make('${autoBackupPrefix}20260901-1200.bkp');
    await AutoBackupRunner().pruneOldBackups(dir.path);
    expect(remaining(), hasLength(1));
  });

  test('a missing folder is not an error', () async {
    await AutoBackupRunner().pruneOldBackups('${dir.path}/tidak-ada');
  });
}
