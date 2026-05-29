import '../entities/password_entity.dart';

abstract class PasswordRepository {
  Future<List<PasswordEntity>> getPasswords();
  Future<void> savePassword(PasswordEntity password);
  Future<void> deletePassword(String id);
}
