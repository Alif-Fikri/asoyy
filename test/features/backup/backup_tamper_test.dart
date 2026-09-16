import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:asoyy/features/backup/services/backup_crypto.dart';
import 'package:asoyy/features/backup/services/backup_service.dart';

const _magic = [0x42, 0x52, 0x53, 0x42];
const _passphrase = 'passphrase-uji';
const _iterations = 2000;

List<int> _u32(int v) => [
      (v >> 24) & 0xff,
      (v >> 16) & 0xff,
      (v >> 8) & 0xff,
      v & 0xff,
    ];

Uint8List _buildV3Backup({required Uint8List payload}) {
  final salt = randomBytes(backupSaltLength);
  final iv = randomBytes(backupIvLength);
  final material =
      deriveKey(_passphrase, salt, iterations: _iterations, length: 64);
  final encryptionKey = Uint8List.fromList(material.sublist(0, 32));
  final macKey = Uint8List.fromList(material.sublist(32, 64));

  final cipher = encryptBytes(payload, encryptionKey, iv);
  final header = <int>[..._magic, 3, ..._u32(_iterations), ...salt, ...iv];
  final tag = computeBackupTag(macKey: macKey, header: header, cipher: cipher);

  return Uint8List.fromList([...header, ...cipher, ...tag]);
}

void main() {
  late Directory dir;
  late BackupService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('backup_tamper');
    service = BackupService();
  });

  tearDown(() async => dir.delete(recursive: true));

  Future<File> write(Uint8List bytes) async {
    final file = File('${dir.path}/backup.bkp');
    await file.writeAsBytes(bytes);
    return file;
  }

  group('an authenticated backup', () {
    test('rejects a file whose ciphertext was altered', () async {
      final bytes = _buildV3Backup(payload: Uint8List.fromList([1, 2, 3, 4]));
      bytes[50] ^= 0x01;

      final file = await write(bytes);
      expect(
        () => service.restoreBackup(file, _passphrase),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a file whose header was altered', () async {
      final bytes = _buildV3Backup(payload: Uint8List.fromList([1, 2, 3, 4]));
      bytes[20] ^= 0x01;

      final file = await write(bytes);
      expect(
        () => service.restoreBackup(file, _passphrase),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a file whose tag was altered', () async {
      final bytes = _buildV3Backup(payload: Uint8List.fromList([1, 2, 3, 4]));
      bytes[bytes.length - 1] ^= 0x01;

      final file = await write(bytes);
      expect(
        () => service.restoreBackup(file, _passphrase),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects the wrong passphrase', () async {
      final bytes = _buildV3Backup(payload: Uint8List.fromList([1, 2, 3, 4]));

      final file = await write(bytes);
      expect(
        () => service.restoreBackup(file, 'passphrase-salah'),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a file claiming a version this build cannot read', () async {
      final bytes = _buildV3Backup(payload: Uint8List.fromList([1, 2, 3, 4]));
      bytes[4] = 99;

      final file = await write(bytes);
      expect(
        () => service.restoreBackup(file, _passphrase),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects a file too short to hold a tag', () async {
      final bytes = _buildV3Backup(payload: Uint8List.fromList([1, 2, 3, 4]));

      final file = await write(Uint8List.fromList(bytes.sublist(0, 50)));
      expect(
        () => service.restoreBackup(file, _passphrase),
        throwsA(isA<BackupException>()),
      );
    });
  });
}
