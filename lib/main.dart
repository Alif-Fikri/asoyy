import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'core/di/injection_container.dart' as di;
import 'features/alarm/data/models/alarm_model.dart';
import 'features/alarm/services/notification_service.dart';
import 'features/calendar/data/models/event_model.dart';
import 'features/debt/data/models/debt_model.dart';
import 'features/finance/data/models/account_model.dart';
import 'features/debt/services/debt_reminder_service.dart';
import 'features/finance/data/models/transaction_model.dart';
import 'features/finance/services/finance_widget_service.dart';
import 'features/finance/services/recurring_reminder_service.dart';
import 'features/password/data/models/password_model.dart';
import 'features/split_bill/data/models/bill_model.dart';
import 'features/split_bill/data/models/participant_model.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  tz_data.initializeTimeZones();
  try {
    final deviceTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimezone.identifier));
  } catch (_) {

  }

  await Hive.initFlutter();
  Hive.registerAdapter(EventModelAdapter());
  Hive.registerAdapter(AlarmModelAdapter());
  Hive.registerAdapter(PasswordModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(ParticipantModelAdapter());
  Hive.registerAdapter(BillModelAdapter());
  Hive.registerAdapter(DebtModelAdapter());
  Hive.registerAdapter(AccountModelAdapter());

  await Future.wait([
    initializeDateFormatting('id_ID', null),
    initializeDateFormatting('en_US', null),
  ]);

  await di.init();
  unawaited(di.sl<FinanceWidgetService>().updateWidget());

  await NotificationService().init();
  await RecurringReminderService().rescheduleAll();
  await DebtReminderService().rescheduleAll();

  runApp(const NexusApp());
}
