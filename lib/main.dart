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
import 'features/finance/data/models/transaction_model.dart';
import 'features/password/data/models/password_model.dart';
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
    tz.setLocalLocation(tz.getLocation(deviceTimezone));
  } catch (_) {

  }


  await Hive.initFlutter();
  Hive.registerAdapter(EventModelAdapter());
  Hive.registerAdapter(AlarmModelAdapter());
  Hive.registerAdapter(PasswordModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());


  await Future.wait([
    initializeDateFormatting('id_ID', null),
    initializeDateFormatting('en_US', null),
  ]);


  await di.init();


  await NotificationService().init();

  runApp(const NexusApp());
}
