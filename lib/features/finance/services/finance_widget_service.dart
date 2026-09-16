import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../../core/usecase/usecase.dart';
import '../domain/usecases/get_finance_summary.dart';

class FinanceWidgetService {
  static const _androidWidgetName = 'FinanceWidgetProvider';

  final GetFinanceSummary getFinanceSummary;

  FinanceWidgetService(this.getFinanceSummary);

  Future<void> updateWidget() async {
    if (!Platform.isAndroid) return;

    final summary = await getFinanceSummary(const NoParams());
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    await HomeWidget.saveWidgetData<String>('balance', fmt.format(summary.totalBalance));
    await HomeWidget.saveWidgetData<String>('today_expense', fmt.format(summary.todayExpense));
    await HomeWidget.saveWidgetData<String>('month_income', fmt.format(summary.monthIncome));
    await HomeWidget.saveWidgetData<String>('month_expense', fmt.format(summary.monthExpense));
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }
}
