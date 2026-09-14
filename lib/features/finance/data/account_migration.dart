import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/entities/account_entity.dart';
import 'account_repository.dart';
import 'models/transaction_model.dart';

const String accountsMigratedFlag = 'accounts_migrated';

Future<void> migrateTransactionsToDefaultAccount(String cashName) async {
  final settings = Hive.box(AppConstants.settingsBox);
  if (settings.get(accountsMigratedFlag) == true) return;

  final accounts = AccountRepository();
  if (accounts.byId(defaultAccountId) == null) {
    await accounts.save(defaultCashAccount(cashName));
  }

  final box = Hive.box<TransactionModel>(AppConstants.transactionsBox);
  final updates = <String, TransactionModel>{};
  for (final model in box.values) {
    if (model.accountId != null) continue;
    updates[model.id] = TransactionModel(
      id: model.id,
      title: model.title,
      amount: model.amount,
      type: model.type,
      category: model.category,
      date: model.date,
      notes: model.notes,
      accountId: defaultAccountId,
      toAccountId: model.toAccountId,
    );
  }
  if (updates.isNotEmpty) await box.putAll(updates);

  await settings.put(accountsMigratedFlag, true);
}
