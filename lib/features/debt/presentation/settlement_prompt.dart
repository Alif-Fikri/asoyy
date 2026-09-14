import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/app_toast.dart';
import '../../finance/data/account_repository.dart';
import '../../finance/presentation/bloc/finance_bloc.dart';
import '../../finance/presentation/bloc/finance_event.dart';
import '../domain/entities/debt_entity.dart';
import '../domain/utils/bill_debt_link.dart';

Future<void> offerToRecordSettlement(
  BuildContext context,
  DebtEntity debt,
) async {
  final s = context.strings;
  final fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final incoming = debt.direction == DebtDirection.theyOweMe;
  final financeBloc = context.read<FinanceBloc>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        incoming ? s.link_record_income_title : s.link_record_expense_title,
      ),
      content: Text(
        incoming
            ? s.link_record_income_desc(debt.personName, fmt.format(debt.amount))
            : s.link_record_expense_desc(
                debt.personName, fmt.format(debt.amount)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(s.link_record_no),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: incoming ? AppColors.income : AppColors.expense,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(s.link_record_yes),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  financeBloc.add(AddTransactionRequested(transactionForSettledDebt(
    debt,
    id: const Uuid().v4(),
    settlementTitle: incoming
        ? s.link_settlement_in(debt.personName)
        : s.link_settlement_out(debt.personName),
    accountId: AccountRepository().fallbackAccountId,
  )));
  AppToast.show(context, s.link_transaction_recorded);
}
