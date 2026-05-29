import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/password_model.dart';

abstract class PasswordLocalDatasource {
  Future<List<PasswordModel>> getPasswords();
  Future<void> savePassword(PasswordModel password);
  Future<void> deletePassword(String id);
}

class PasswordLocalDatasourceImpl implements PasswordLocalDatasource {
  final Box<PasswordModel> box;
  PasswordLocalDatasourceImpl(this.box);

  static Future<PasswordLocalDatasourceImpl> create() async {
    final box = await Hive.openBox<PasswordModel>(AppConstants.passwordsBox);
    return PasswordLocalDatasourceImpl(box);
  }

  @override
  Future<List<PasswordModel>> getPasswords() async => box.values.toList();

  @override
  Future<void> savePassword(PasswordModel password) =>
      box.put(password.id, password);

  @override
  Future<void> deletePassword(String id) => box.delete(id);
}
