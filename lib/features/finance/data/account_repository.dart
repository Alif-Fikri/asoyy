import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/entities/account_entity.dart';
import 'models/account_model.dart';

class AccountRepository {
  Box<AccountModel> get _box =>
      Hive.box<AccountModel>(AppConstants.accountsBox);

  static Future<Box<AccountModel>> open() =>
      Hive.openBox<AccountModel>(AppConstants.accountsBox);

  List<AccountEntity> getAll() =>
      _box.values.map((m) => m.toEntity()).toList(growable: false);

  AccountEntity? byId(String id) => _box.get(id)?.toEntity();

  Future<void> save(AccountEntity account) =>
      _box.put(account.id, AccountModel.fromEntity(account));

  Future<void> delete(String id) => _box.delete(id);

  bool get isEmpty => _box.isEmpty;
}
