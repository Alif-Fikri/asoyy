enum AccountType { cash, bank, ewallet, other }

class AccountEntity {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0,
  });

  AccountEntity copyWith({
    String? name,
    AccountType? type,
    double? initialBalance,
  }) =>
      AccountEntity(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        initialBalance: initialBalance ?? this.initialBalance,
      );
}

const String defaultAccountId = 'acc_cash_default';

AccountEntity defaultCashAccount(String name) => AccountEntity(
      id: defaultAccountId,
      name: name,
      type: AccountType.cash,
    );

AccountType accountTypeFromString(String? raw) {
  for (final t in AccountType.values) {
    if (t.name == raw) return t;
  }
  return AccountType.other;
}
