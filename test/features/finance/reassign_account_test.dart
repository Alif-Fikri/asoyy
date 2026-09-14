import 'dart:io';

import 'package:asoyy/core/constants/app_constants.dart';
import 'package:asoyy/features/finance/data/datasources/finance_local_datasource.dart';
import 'package:asoyy/features/finance/data/models/transaction_model.dart';
import 'package:asoyy/features/finance/domain/entities/account_entity.dart';
import 'package:asoyy/features/finance/domain/entities/transaction_entity.dart';
import 'package:asoyy/features/finance/domain/utils/account_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

TransactionModel row(
  String id,
  String type,
  double amount, {
  String? from,
  String? to,
}) =>
    TransactionModel(
      id: id,
      title: id,
      amount: amount,
      type: type,
      category: type == 'transfer' ? transferCategory : 'Makan',
      date: DateTime(2026, 6, 1),
      accountId: from,
      toAccountId: to,
    );

void main() {
  late Directory dir;
  late FinanceLocalDatasourceImpl ds;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('reassign');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    ds = FinanceLocalDatasourceImpl(
      await Hive.openBox<TransactionModel>(AppConstants.transactionsBox),
    );
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<List<TransactionEntity>> entities() async =>
      (await ds.getTransactions()).map((m) => m.toEntity()).toList();

  test('moves transactions off the deleted wallet', () async {
    await ds.addTransaction(row('a', 'expense', 100000, from: 'cash'));
    await ds.addTransaction(row('b', 'income', 300000, from: 'cash'));

    final moved = await ds.reassignAccount('cash', 'bca');

    expect(moved, 2);
    for (final t in await entities()) {
      expect(t.accountId, 'bca', reason: t.id);
    }
  });

  test('leaves other wallets alone', () async {
    await ds.addTransaction(row('a', 'expense', 100000, from: 'cash'));
    await ds.addTransaction(row('b', 'expense', 50000, from: 'gopay'));

    final moved = await ds.reassignAccount('cash', 'bca');

    expect(moved, 1);
    final byId = {for (final t in await entities()) t.id: t};
    expect(byId['a']!.accountId, 'bca');
    expect(byId['b']!.accountId, 'gopay');
  });

  test('rewrites both sides of a transfer', () async {
    await ds.addTransaction(
      row('t', 'transfer', 200000, from: 'cash', to: 'bca'),
    );
    await ds.addTransaction(
      row('u', 'transfer', 50000, from: 'bca', to: 'cash'),
    );

    await ds.reassignAccount('cash', 'gopay');

    final byId = {for (final t in await entities()) t.id: t};
    expect(byId['t']!.accountId, 'gopay');
    expect(byId['t']!.toAccountId, 'bca');
    expect(byId['u']!.accountId, 'bca');
    expect(byId['u']!.toAccountId, 'gopay');
  });

  test('the total balance is unchanged by the move', () async {
    await ds.addTransaction(row('a', 'income', 1000000, from: 'cash'));
    await ds.addTransaction(row('b', 'expense', 250000, from: 'cash'));
    await ds.addTransaction(
      row('t', 'transfer', 200000, from: 'bca', to: 'cash'),
    );

    const cash = AccountEntity(id: 'cash', name: 'Cash', type: AccountType.cash);
    const bca = AccountEntity(id: 'bca', name: 'BCA', type: AccountType.bank);

    final before = totalBalance([cash, bca], await entities());
    await ds.reassignAccount('cash', 'bca');
    final after = totalBalance([bca], await entities());

    expect(after, before);
  });

  test('a self-transfer created by the move nets to zero', () async {
    await ds.addTransaction(
      row('t', 'transfer', 200000, from: 'bca', to: 'cash'),
    );

    await ds.reassignAccount('cash', 'bca');

    const bca = AccountEntity(
      id: 'bca',
      name: 'BCA',
      type: AccountType.bank,
      initialBalance: 500000,
    );
    expect(accountBalance(bca, await entities()), 500000);
  });

  test('moving a wallet nobody uses changes nothing', () async {
    await ds.addTransaction(row('a', 'expense', 100000, from: 'cash'));

    expect(await ds.reassignAccount('kosong', 'bca'), 0);
    expect((await entities()).single.accountId, 'cash');
  });
}
