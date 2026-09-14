import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../../backup/services/backup_crypto.dart';
import '../domain/entities/auth_method.dart';
import 'datasources/password_local_datasource.dart';
import 'models/password_model.dart';

const int authPbkdf2Iterations = 120000;
const int authSaltLength = 16;

class AuthConfigRepository {
  static const _methodKey = 'auth_method';
  static const _hashKey = 'auth_hash';
  static const _saltKey = 'auth_salt';

  Box get _box => Hive.box(AppConstants.settingsBox);

  AuthMethod? get currentMethod =>
      AuthMethod.fromString(_box.get(_methodKey) as String?);

  bool get isConfigured => currentMethod != null;

  Future<void> setMethod(AuthMethod method, {String? secret}) async {
    await _box.put(_methodKey, method.name);
    if (method == AuthMethod.biometric) {
      await _box.delete(_hashKey);
      await _box.delete(_saltKey);
    } else {
      if (secret == null || secret.isEmpty) {
        throw ArgumentError('secret required for ${method.name}');
      }
      await _store(secret);
    }
  }

  Future<void> clear() async {
    await _box.delete(_methodKey);
    await _box.delete(_hashKey);
    await _box.delete(_saltKey);
  }

  Future<void> clearPasswords() async {
    if (Hive.isBoxOpen(AppConstants.passwordsBox)) {
      await Hive.box<PasswordModel>(AppConstants.passwordsBox).clear();
      return;
    }
    await resetVault();
  }

  Future<bool> verify(String secret) async {
    final stored = _box.get(_hashKey) as String?;
    if (stored == null) return false;

    final salt = _storedSalt();
    if (salt != null) {
      return _constantTimeEquals(stored, _stretch(secret, salt));
    }

    if (!_constantTimeEquals(stored, _legacyHash(secret))) return false;
    await _store(secret);
    return true;
  }

  Future<void> _store(String secret) async {
    final salt = randomBytes(authSaltLength);
    await _box.put(_saltKey, base64Encode(salt));
    await _box.put(_hashKey, _stretch(secret, salt));
  }

  Uint8List? _storedSalt() {
    final raw = _box.get(_saltKey) as String?;
    if (raw == null) return null;
    try {
      return Uint8List.fromList(base64Decode(raw));
    } catch (_) {
      return null;
    }
  }

  String _stretch(String secret, Uint8List salt) => base64Encode(
        deriveKey(secret, salt, iterations: authPbkdf2Iterations),
      );

  String _legacyHash(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
