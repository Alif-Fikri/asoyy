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
import '../../features/finance/data/repositories/finance_repository_impl.dart';
import '../../features/finance/domain/repositories/finance_repository.dart';
import '../../features/finance/domain/usecases/add_transaction.dart';
import '../../features/finance/domain/usecases/delete_transaction.dart';
import '../../features/finance/domain/usecases/get_transactions.dart';
import '../../features/finance/presentation/bloc/finance_bloc.dart';

import '../../features/password/data/datasources/password_local_datasource.dart';
import '../../features/password/data/repositories/password_repository_impl.dart';
import '../../features/password/domain/repositories/password_repository.dart';
import '../../features/password/domain/usecases/delete_password.dart';
import '../../features/password/domain/usecases/get_passwords.dart';
import '../../features/password/domain/usecases/save_password.dart';
import '../../features/password/presentation/bloc/password_bloc.dart';

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

  final financeDs = await FinanceLocalDatasourceImpl.create();
  sl.registerSingleton<FinanceLocalDatasource>(financeDs);
  sl.registerSingleton<FinanceRepository>(
      FinanceRepositoryImpl(sl<FinanceLocalDatasource>()));
  sl.registerFactory(() => FinanceBloc(
        getTransactions: GetTransactions(sl()),
        addTransaction: AddTransaction(sl()),
        deleteTransaction: DeleteTransaction(sl()),
      ));
}
