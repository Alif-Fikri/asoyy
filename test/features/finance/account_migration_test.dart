import 'dart:io';

import 'package:asoyy/core/constants/app_constants.dart';
import 'package:asoyy/features/finance/data/account_migration.dart';
import 'package:asoyy/features/finance/data/account_repository.dart';
import 'package:asoyy/features/finance/data/models/account_model.dart';
import 'package:asoyy/features/finance/data/models/transaction_model.dart';
import 'package:asoyy/features/finance/domain/entities/account_entity.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/utils/account_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

TransactionModel legacy(String id, String type, double amount) =>
    TransactionModel(
      id: id,
      title: 'lama $id',
      amount: amount,
      type: type,
      category: 'Makan',
      date: DateTime(2026, 5, 1),
    );

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('acc_mig');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(AccountModelAdapter());
    }
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox<TransactionModel>(AppConstants.transactionsBox);
    await AccountRepository.open();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Box<TransactionModel> txBox() =>
      Hive.box<TransactionModel>(AppConstants.transactionsBox);

  test('creates a default cash account when there is none', () async {
    await migrateTransactionsToDefaultAccount('Tunai');

    final accounts = AccountRepository().getAll();
    expect(accounts, hasLength(1));
    expect(accounts.single.id, defaultAccountId);
    expect(accounts.single.name, 'Tunai');
    expect(accounts.single.type, AccountType.cash);
  });

  test('assigns every existing transaction to that account', () async {
    await txBox().putAll({
      'a': legacy('a', 'income', 1000000),
      'b': legacy('b', 'expense', 250000),
    });

    await migrateTransactionsToDefaultAccount('Tunai');

    for (final m in txBox().values) {
      expect(m.accountId, defaultAccountId, reason: m.id);
    }
  });

  test('the balance after migration equals the old net', () async {
    await txBox().putAll({
      'a': legacy('a', 'income', 1000000),
      'b': legacy('b', 'expense', 250000),
    });

    await migrateTransactionsToDefaultAccount('Tunai');

    final accounts = AccountRepository().getAll();
    final txs = txBox()
        .values
        .map((m) => m.toEntity())
        .toList(growable: false);
    expect(totalBalance(accounts, txs), 750000);
  });

  test('runs only once and leaves later choices alone', () async {
    await txBox().put('a', legacy('a', 'expense', 100000));
    await migrateTransactionsToDefaultAccount('Tunai');

    final accounts = AccountRepository();
    await accounts.save(const AccountEntity(
      id: 'bca',
      name: 'BCA',
      type: AccountType.bank,
    ));
    final moved = txBox().get('a')!;
    await txBox().put(
      'a',
      TransactionModel(
        id: moved.id,
        title: moved.title,
        amount: moved.amount,
        type: moved.type,
        category: moved.category,
        date: moved.date,
        accountId: 'bca',
      ),
    );

    await migrateTransactionsToDefaultAccount('Tunai');

    expect(txBox().get('a')!.accountId, 'bca');
    expect(accounts.getAll(), hasLength(2));
  });

  test('a fresh install migrates to an account with no transactions', () async {
    await migrateTransactionsToDefaultAccount('Cash');

    expect(AccountRepository().getAll(), hasLength(1));
    expect(txBox().values, isEmpty);
  });

  test('legacy rows still decode to the right type', () async {
    await txBox().put('a', legacy('a', 'income', 5000));
    await migrateTransactionsToDefaultAccount('Tunai');

    final entity = txBox().get('a')!.toEntity();
    expect(entity.type, TransactionType.income);
    expect(entity.isIncome, isTrue);
    expect(entity.isTransfer, isFalse);
  });
}
