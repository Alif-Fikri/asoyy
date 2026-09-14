import '../entities/account_entity.dart';
import '../entities/transaction_entity.dart';

double accountBalance(
  AccountEntity account,
  Iterable<TransactionEntity> transactions,
) {
  var total = account.initialBalance;
  for (final t in transactions) {
    switch (t.type) {
      case TransactionType.income:
        if (t.accountId == account.id) total += t.amount;
      case TransactionType.expense:
        if (t.accountId == account.id) total -= t.amount;
      case TransactionType.transfer:
        if (t.accountId == account.id) total -= t.amount;
        if (t.toAccountId == account.id) total += t.amount;
    }
  }
  return total;
}

double unassignedBalance(
  Iterable<AccountEntity> accounts,
  Iterable<TransactionEntity> transactions,
) {
  final known = accounts.map((a) => a.id).toSet();
  var total = 0.0;
  for (final t in transactions) {
    if (t.isTransfer) continue;
    if (known.contains(t.accountId)) continue;
    total += t.isIncome ? t.amount : -t.amount;
  }
  return total;
}

double totalBalance(
  Iterable<AccountEntity> accounts,
  Iterable<TransactionEntity> transactions,
) {
  var total = 0.0;
  for (final account in accounts) {
    total += accountBalance(account, transactions);
  }
  return total + unassignedBalance(accounts, transactions);
}

Map<String, double> balanceByAccount(
  Iterable<AccountEntity> accounts,
  Iterable<TransactionEntity> transactions,
) =>
    {for (final a in accounts) a.id: accountBalance(a, transactions)};
