import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

import '../../features/alarm/data/datasources/alarm_local_datasource.dart';
import '../../features/alarm/data/repositories/alarm_repository_impl.dart';
import '../../features/alarm/domain/repositories/alarm_repository.dart';
import '../../features/alarm/domain/usecases/add_alarm.dart';
import '../../features/alarm/domain/usecases/delete_alarm.dart';
import '../../features/alarm/domain/usecases/get_alarms.dart';
import '../../features/alarm/domain/usecases/toggle_alarm.dart';
import '../../features/alarm/presentation/bloc/alarm_bloc.dart';
import '../../features/alarm/services/notification_service.dart';

import '../../features/calendar/data/datasources/calendar_local_datasource.dart';
import '../../features/calendar/data/repositories/calendar_repository_impl.dart';
import '../../features/calendar/domain/repositories/calendar_repository.dart';
import '../../features/calendar/domain/usecases/add_event.dart';
import '../../features/calendar/domain/usecases/delete_event.dart';
import '../../features/calendar/domain/usecases/get_events.dart';
import '../../features/calendar/presentation/bloc/calendar_bloc.dart';

import '../../features/calculator/presentation/bloc/calculator_bloc.dart';

import '../../features/converter/data/converter_rates_repository.dart';
import '../../features/converter/presentation/bloc/converter_cubit.dart';

import '../../features/finance/data/datasources/finance_local_datasource.dart';
import '../../features/finance/data/account_migration.dart';
import '../../features/finance/data/account_repository.dart';
import '../../features/finance/data/recurring_transaction_repository.dart';
import '../../features/finance/data/repositories/finance_repository_impl.dart';
import '../../features/finance/domain/repositories/finance_repository.dart';
import '../../features/finance/domain/usecases/add_transaction.dart';
import '../../features/finance/domain/usecases/delete_transaction.dart';
import '../../features/finance/domain/usecases/get_finance_summary.dart';
import '../../features/finance/domain/usecases/get_transactions.dart';
import '../../features/finance/presentation/bloc/finance_bloc.dart';
import '../../features/finance/services/finance_widget_service.dart';

import '../../features/password/data/datasources/password_local_datasource.dart';
import '../../features/password/data/repositories/password_repository_impl.dart';
import '../../features/password/domain/repositories/password_repository.dart';
import '../../features/password/domain/usecases/delete_password.dart';
import '../../features/password/domain/usecases/get_passwords.dart';
import '../../features/password/domain/usecases/save_password.dart';
import '../../features/password/presentation/bloc/password_bloc.dart';

import '../../features/split_bill/data/datasources/split_bill_local_datasource.dart';
import '../../features/split_bill/data/repositories/split_bill_repository_impl.dart';
import '../../features/split_bill/domain/repositories/split_bill_repository.dart';
import '../../features/split_bill/domain/usecases/add_bill.dart';
import '../../features/split_bill/domain/usecases/delete_bill.dart';
import '../../features/split_bill/domain/usecases/get_bills.dart';
import '../../features/split_bill/domain/usecases/update_bill.dart';
import '../../features/split_bill/presentation/bloc/split_bill_bloc.dart';

import '../../features/debt/data/datasources/debt_local_datasource.dart';
import '../../features/debt/data/repositories/debt_repository_impl.dart';
import '../../features/debt/domain/repositories/debt_repository.dart';
import '../../features/debt/domain/usecases/add_debt.dart';
import '../../features/debt/domain/usecases/delete_debt.dart';
import '../../features/debt/domain/usecases/get_debts.dart';
import '../../features/debt/domain/usecases/update_debt.dart';
import '../../features/debt/presentation/bloc/debt_bloc.dart';
import '../../features/debt/services/debt_reminder_service.dart';

final sl = GetIt.instance;

Future<void> init() async {

  await Hive.openBox(AppConstants.settingsBox);

  final notificationService = NotificationService();
  await notificationService.init();
  sl.registerSingleton<NotificationService>(notificationService);

  final calendarDs = await CalendarLocalDatasourceImpl.create();
  sl.registerSingleton<CalendarLocalDatasource>(calendarDs);
  sl.registerSingleton<CalendarRepository>(
      CalendarRepositoryImpl(sl<CalendarLocalDatasource>()));
  sl.registerFactory(() => CalendarBloc(
        getEvents: GetEvents(sl()),
        addEvent: AddEvent(sl()),
        deleteEvent: DeleteEvent(sl()),
      ));

  final alarmDs = await AlarmLocalDatasourceImpl.create();
  sl.registerSingleton<AlarmLocalDatasource>(alarmDs);
  sl.registerSingleton<AlarmRepository>(
      AlarmRepositoryImpl(sl<AlarmLocalDatasource>()));
  sl.registerFactory(() => AlarmBloc(
        getAlarms: GetAlarms(sl()),
        addAlarm: AddAlarm(sl()),
        toggleAlarm: ToggleAlarm(sl()),
        deleteAlarm: DeleteAlarm(sl()),
        notificationService: sl(),
      ));

  sl.registerFactory(() => CalculatorBloc());

  sl.registerLazySingleton(() => ConverterRatesRepository());
  sl.registerFactory(() => ConverterCubit(sl()));

  final passwordDs = await PasswordLocalDatasourceImpl.create();
  sl.registerSingleton<PasswordLocalDatasource>(passwordDs);
  sl.registerSingleton<PasswordRepository>(
      PasswordRepositoryImpl(sl<PasswordLocalDatasource>()));
  sl.registerFactory(() => PasswordBloc(
        getPasswords: GetPasswords(sl()),
        savePassword: SavePassword(sl()),
        deletePassword: DeletePassword(sl()),
      ));

  await AccountRepository.open();
  final financeDs = await FinanceLocalDatasourceImpl.create();
  final appLocale =
      Hive.box(AppConstants.settingsBox).get('locale', defaultValue: 'id');
  await migrateTransactionsToDefaultAccount(
    appLocale == 'id' ? 'Tunai' : 'Cash',
  );
  sl.registerSingleton<FinanceLocalDatasource>(financeDs);
  sl.registerSingleton<FinanceRepository>(
      FinanceRepositoryImpl(sl<FinanceLocalDatasource>()));
  sl.registerLazySingleton(() => RecurringTransactionRepository());
  await sl<RecurringTransactionRepository>()
      .generateDueTransactions(sl<FinanceRepository>());
  sl.registerLazySingleton(
      () => FinanceWidgetService(GetFinanceSummary(sl<FinanceRepository>())));
  sl.registerFactory(() => FinanceBloc(
        getTransactions: GetTransactions(sl()),
        addTransaction: AddTransaction(sl()),
        deleteTransaction: DeleteTransaction(sl()),
        financeWidgetService: sl<FinanceWidgetService>(),
      ));

  final splitBillDs = await SplitBillLocalDatasourceImpl.create();
  sl.registerSingleton<SplitBillLocalDatasource>(splitBillDs);
  sl.registerSingleton<SplitBillRepository>(
      SplitBillRepositoryImpl(sl<SplitBillLocalDatasource>()));

  final debtDs = await DebtLocalDatasourceImpl.create();
  sl.registerSingleton<DebtLocalDatasource>(debtDs);
  sl.registerSingleton<DebtRepository>(DebtRepositoryImpl(sl<DebtLocalDatasource>()));
  sl.registerLazySingleton(() => DebtReminderService());

  sl.registerFactory(() => SplitBillBloc(
        getBills: GetBills(sl()),
        addBill: AddBill(sl()),
        updateBill: UpdateBill(sl()),
        deleteBill: DeleteBill(sl()),
        reminderService: sl<DebtReminderService>(),
      ));

  sl.registerFactory(() => DebtBloc(
        getDebts: GetDebts(sl()),
        addDebt: AddDebt(sl()),
        updateDebt: UpdateDebt(sl()),
        deleteDebt: DeleteDebt(sl()),
        reminderService: sl<DebtReminderService>(),
      ));
}
