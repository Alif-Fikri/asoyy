import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_colors.dart';
import 'core/di/injection_container.dart' as di;
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_bloc.dart';
import 'core/theme/app_color_theme.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/alarm/presentation/bloc/alarm_bloc.dart';
import 'features/alarm/presentation/bloc/alarm_event.dart';
import 'features/alarm/presentation/bloc/alarm_state.dart';
import 'features/alarm/presentation/pages/alarm_page.dart';
import 'features/alarm/services/notification_service.dart';
import 'features/calendar/presentation/bloc/calendar_bloc.dart';
import 'features/calendar/presentation/bloc/calendar_event.dart';
import 'features/calendar/presentation/pages/calendar_page.dart';
import 'features/calculator/presentation/bloc/calculator_bloc.dart';
import 'features/finance/presentation/bloc/finance_bloc.dart';
import 'features/finance/presentation/bloc/finance_event.dart';
import 'features/finance/presentation/pages/finance_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/password/data/auth_config_repository.dart';
import 'features/password/presentation/bloc/password_bloc.dart';
import 'features/password/presentation/bloc/password_event.dart';
import 'features/password/presentation/pages/password_auth_gate.dart';
import 'features/password/presentation/pages/password_page.dart';

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LocaleBloc()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleBloc, Locale>(
            builder: (context, locale) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => di.sl<CalendarBloc>()..add(LoadEvents()),
                  ),
                  BlocProvider(
                    create: (_) => di.sl<AlarmBloc>()..add(LoadAlarms()),
                  ),
                  BlocProvider(create: (_) => di.sl<CalculatorBloc>()),
                  BlocProvider(
                    create: (_) => di.sl<PasswordBloc>()..add(LoadPasswords()),
                  ),
                  BlocProvider(
                    create:
                        (_) => di.sl<FinanceBloc>()..add(LoadTransactions()),
                  ),
                ],
                child: MaterialApp(
                  title: 'Vela',
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: themeMode,
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  supportedLocales: const [Locale('id'), Locale('en')],
                  localizationsDelegates: const [
                    NexusLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: const _MainShell(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _passwordAuthenticated = false;
  final AuthConfigRepository _authRepo = AuthConfigRepository();

  AlarmSet _previousRinging = AlarmSet.empty();
  StreamSubscription<AlarmSet>? _alarmRingSubscription;
  bool _isRingDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _previousRinging = Alarm.ringing.value;
    _alarmRingSubscription = Alarm.ringing.listen(_onRingingChanged);
  }

  @override
  void dispose() {
    _alarmRingSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      setState(() => _passwordAuthenticated = false);
    }
  }

  Future<void> _onRingingChanged(AlarmSet currentRinging) async {
    final newlyRinging =
        currentRinging.alarms
            .where((a) => !_previousRinging.containsId(a.id))
            .toList();
    _previousRinging = currentRinging;
    for (final alarmSettings in newlyRinging) {
      await _showAlarmDialog(alarmSettings);
    }
  }

  Future<void> _showAlarmDialog(AlarmSettings alarmSettings) async {
    if (_isRingDialogShowing || !mounted) return;
    _isRingDialogShowing = true;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _AlarmRingDialog(
            label: alarmSettings.notificationSettings.title,
            onStop: () async {
              await Alarm.stop(alarmSettings.id);
              if (mounted) _rescheduleIfRecurring(alarmSettings.id);
            },
          ),
    );
    _isRingDialogShowing = false;
  }

  void _rescheduleIfRecurring(int ringId) {
    final state = context.read<AlarmBloc>().state;
    if (state is! AlarmLoaded) return;
    final stopText = context.strings.alarm_stop;
    for (final alarm in state.alarms) {
      if (!alarm.isEnabled || alarm.days.isEmpty) continue;
      final baseId = alarm.id.hashCode.abs() % 100000;
      for (final day in alarm.days) {
        if ((baseId + day) % 100000 == ringId) {
          NotificationService().scheduleAlarm(alarm, stopButtonText: stopText);
          return;
        }
      }
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return HomePage(onNavigate: (i) => setState(() => _currentIndex = i));
      case 1:
        return const CalendarPage();
      case 2:
        return const AlarmPage();
      case 3:
        return const FinancePage();
      case 4:
        if (!_passwordAuthenticated) {
          return PasswordAuthGate(
            repo: _authRepo,
            onAuthenticated:
                () => setState(() => _passwordAuthenticated = true),
          );
        }
        return PasswordPage(authRepo: _authRepo);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(5, _buildPage),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          surfaceTintColor: AppColors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          destinations: [
            NavigationDestination(
              icon: const Icon(CupertinoIcons.house),
              selectedIcon: const Icon(CupertinoIcons.house_fill),
              label: s.nav_home,
            ),
            NavigationDestination(
              icon: const Icon(CupertinoIcons.calendar),
              selectedIcon: const Icon(CupertinoIcons.calendar_today),
              label: s.nav_calendar,
            ),
            NavigationDestination(
              icon: const Icon(CupertinoIcons.alarm),
              selectedIcon: const Icon(CupertinoIcons.alarm_fill),
              label: s.nav_alarm,
            ),
            NavigationDestination(
              icon: const Icon(CupertinoIcons.creditcard),
              selectedIcon: const Icon(CupertinoIcons.creditcard_fill),
              label: s.nav_finance,
            ),
            NavigationDestination(
              icon: const Icon(CupertinoIcons.lock),
              selectedIcon: const Icon(CupertinoIcons.lock_fill),
              label: s.nav_password,
            ),
          ],
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }
}

class _AlarmRingDialog extends StatelessWidget {
  const _AlarmRingDialog({required this.label, required this.onStop});

  final String label;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        backgroundColor: AppColors.alarmColor,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.alarm_fill,
                size: 72,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                label.isEmpty ? s.alarm_notification_title : label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 64),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.alarmColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(CupertinoIcons.stop_fill),
                label: Text(s.alarm_stop),
                onPressed: () {
                  Navigator.of(context).pop();
                  onStop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
