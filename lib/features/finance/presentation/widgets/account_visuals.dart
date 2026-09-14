import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/account_entity.dart';

IconData accountIcon(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return CupertinoIcons.money_dollar;
    case AccountType.bank:
      return CupertinoIcons.building_2_fill;
    case AccountType.ewallet:
      return CupertinoIcons.creditcard;
    case AccountType.other:
      return CupertinoIcons.square_stack_3d_up;
  }
}

Color accountColor(AccountType type) {
  switch (type) {
    case AccountType.cash:
      return AppColors.income;
    case AccountType.bank:
      return AppColors.primary;
    case AccountType.ewallet:
      return AppColors.calendarColor;
    case AccountType.other:
      return AppColors.passwordColor;
  }
}

String accountTypeLabel(AccountType type, AppStrings s) {
  switch (type) {
    case AccountType.cash:
      return s.acc_type_cash;
    case AccountType.bank:
      return s.acc_type_bank;
    case AccountType.ewallet:
      return s.acc_type_ewallet;
    case AccountType.other:
      return s.acc_type_other;
  }
}
