import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../backup/services/backup_crypto.dart';

const int vaultKeyLength = 32;

class VaultKeyStore {
  static const _keyName = 'password_vault_key';

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<Uint8List?> read() async {
    try {
      final stored = await _storage.read(key: _keyName);
      if (stored == null) return null;
      final bytes = base64Decode(stored);
      if (bytes.length != vaultKeyLength) return null;
      return Uint8List.fromList(bytes);
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Uint8List key) async {
    if (key.length != vaultKeyLength) {
      throw ArgumentError('vault key must be $vaultKeyLength bytes');
    }
    await _storage.write(key: _keyName, value: base64Encode(key));
  }

  Future<Uint8List> readOrCreate() async {
    final existing = await read();
    if (existing != null) return existing;
    final created = randomBytes(vaultKeyLength);
    await write(created);
    return created;
  }

  Future<void> delete() => _storage.delete(key: _keyName);
}
