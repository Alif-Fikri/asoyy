import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/entities/auth_method.dart';
import 'models/password_model.dart';

class AuthConfigRepository {
  static const _methodKey = 'auth_method';
  static const _hashKey = 'auth_hash';

  Box get _box => Hive.box(AppConstants.settingsBox);

  AuthMethod? get currentMethod =>
      AuthMethod.fromString(_box.get(_methodKey) as String?);

  bool get isConfigured => currentMethod != null;


  Future<void> setMethod(AuthMethod method, {String? secret}) async {
    await _box.put(_methodKey, method.name);
    if (method == AuthMethod.biometric) {
      await _box.delete(_hashKey);
    } else {
      if (secret == null || secret.isEmpty) {
        throw ArgumentError('secret required for ${method.name}');
      }
      await _box.put(_hashKey, _hash(secret));
    }
  }


  Future<void> clear() async {
    await _box.delete(_methodKey);
    await _box.delete(_hashKey);
  }

  Future<void> clearPasswords() async {
    await Hive.box<PasswordModel>(AppConstants.passwordsBox).clear();
  }


  bool verify(String secret) {
    final stored = _box.get(_hashKey) as String?;
    if (stored == null) return false;
    return stored == _hash(secret);
  }

  String _hash(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
