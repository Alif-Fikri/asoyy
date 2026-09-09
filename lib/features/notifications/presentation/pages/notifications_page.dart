import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../alarm/presentation/bloc/alarm_bloc.dart';
import '../../../alarm/presentation/bloc/alarm_event.dart';
import '../../../alarm/presentation/bloc/alarm_state.dart';
import '../../../alarm/presentation/pages/alarm_page.dart';
import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../calendar/presentation/bloc/calendar_state.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../finance/data/recurring_transaction_repository.dart';
import '../../../finance/presentation/bloc/finance_bloc.dart';
import '../../../finance/presentation/bloc/finance_event.dart';
import '../../../finance/presentation/pages/recurring_transactions_page.dart';
import '../../../finance/services/recurring_reminder_service.dart';
import '../../data/notification_mute_repository.dart';
import '../../domain/reminder_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _recurringRepo = RecurringTransactionRepository();
  final _reminderService = RecurringReminderService();
  final _muteRepo = NotificationMuteRepository();

  Future<void> _toggle(ReminderItem item, bool enabled) async {
    if (item.kind == ReminderKind.alarm) {
      final state = context.read<AlarmBloc>().state;
      if (state is AlarmLoaded) {
        final alarm = state.alarms.where((a) => a.id == item.id).firstOrNull;
        if (alarm != null) {
          context.read<AlarmBloc>().add(ToggleAlarmRequested(
                alarm.copyWith(isEnabled: enabled),
                stopButtonText: context.strings.alarm_stop,
              ));
        }
      }
      return;
    }

    await _muteRepo.setMuted(item.id, !enabled);
    if (item.kind == ReminderKind.recurringBill) {
      if (enabled) {
        final bill =
            _recurringRepo.getAll().where((b) => b.id == item.id).firstOrNull;
        if (bill != null) await _reminderService.scheduleReminder(bill);
      } else {
        await _reminderService.cancelReminder(item.id);
      }
    }
    setState(() {});
  }

  void _openTarget(BuildContext context, ReminderItem item) {
    final Widget page = switch (item.kind) {
      ReminderKind.alarm => const AlarmPage(),
      ReminderKind.event || ReminderKind.holiday || ReminderKind.payday =>
        const CalendarPage(),
      ReminderKind.recurringBill => RecurringTransactionsPage(
          onChanged: () => context.read<FinanceBloc>().add(LoadTransactions()),
        ),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.nav_notifications),
      body: BlocBuilder<AlarmBloc, AlarmState>(
        builder: (context, alarmState) {
          return BlocBuilder<CalendarBloc, CalendarState>(
            builder: (context, calendarState) {
              final isId = context.currentLocale.languageCode == 'id';
              final now = DateTime.now();

              final items = buildReminders(
                alarms: alarmState is AlarmLoaded
                    ? alarmState.alarms.where((a) => a.isEnabled).toList()
                    : const [],
                events: calendarState is CalendarLoaded
                    ? calendarState.events
                    : const [],
                holidays: calendarState is CalendarLoaded
                    ? calendarState.holidays
                    : const [],
                paydayDay: calendarState is CalendarLoaded
                    ? calendarState.paydayDay
                    : null,
                recurringBills: _recurringRepo.getAll(),
                now: now,
                alarmColor: AppColors.alarmColor,
                holidayColor: AppColors.calendarColor,
                paydayColor: AppColors.income,
                recurringBillColor: AppColors.financeColor,
                paydayLabel: s.cal_payday,
                isId: isId,
                mutedIds: _muteRepo.getMuted(),
              );

              if (items.isEmpty) {
                return EmptyStateWidget(
                  icon: CupertinoIcons.bell_slash,
                  title: s.notif_empty_title,
                  subtitle: s.notif_empty_subtitle,
                );
              }

              final today = DateTime(now.year, now.month, now.day);
              final tomorrow = today.add(const Duration(days: 1));
              final groups = <String, List<ReminderItem>>{
                s.notif_group_today: [],
                s.notif_group_tomorrow: [],
                s.notif_group_upcoming: [],
              };

              for (final item in items) {
                final day =
                    DateTime(item.when.year, item.when.month, item.when.day);
                if (day == today) {
                  groups[s.notif_group_today]!.add(item);
                } else if (day == tomorrow) {
                  groups[s.notif_group_tomorrow]!.add(item);
                } else {
                  groups[s.notif_group_upcoming]!.add(item);
                }
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  0,
                  16,
                  0,
                  MediaQuery.of(context).padding.bottom + 80,
                ),
                children: [
                  for (final entry in groups.entries)
                    if (entry.value.isNotEmpty)
                      IosSection(
                        header: entry.key,
                        children: entry.value
                            .map((item) => _ReminderRow(
                                  item: item,
                                  isId: isId,
                                  onToggle: (v) => _toggle(item, v),
                                  onTap: () => _openTarget(context, item),
                                ))
                            .toList(),
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _ReminderRow extends StatelessWidget {
  final ReminderItem item;
  final bool isId;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const _ReminderRow({
    required this.item,
    required this.isId,
    required this.onToggle,
    required this.onTap,
  });

  IconData get _icon => switch (item.kind) {
        ReminderKind.alarm => CupertinoIcons.alarm,
        ReminderKind.event => CupertinoIcons.calendar,
        ReminderKind.holiday => CupertinoIcons.flag,
        ReminderKind.payday => CupertinoIcons.money_dollar_circle,
        ReminderKind.recurringBill => CupertinoIcons.repeat,
      };

  String _kindLabel(AppStrings s) => switch (item.kind) {
        ReminderKind.alarm => s.notif_kind_alarm,
        ReminderKind.event => s.notif_kind_event,
        ReminderKind.holiday => s.notif_kind_holiday,
        ReminderKind.payday => s.notif_kind_payday,
        ReminderKind.recurringBill => s.notif_kind_recurring_bill,
      };

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final locale = isId ? 'id_ID' : 'en_US';
    final pattern = item.hasTime ? 'EEE, d MMM · HH:mm' : 'EEE, d MMM';
    final subtitle =
        '${_kindLabel(s)} · ${DateFormat(pattern, locale).format(item.when)}'
        '${item.enabled ? '' : ' · ${s.notif_off_hint}'}';

    return IosRow(
      leading: IosIcon(
        icon: _icon,
        color: item.enabled ? item.color : c.textHint,
      ),
      title: item.title,
      titleColor: item.enabled ? null : c.textHint,
      subtitle: subtitle,
      onTap: onTap,
      trailing: _NotifToggle(value: item.enabled, onChanged: onToggle),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : c.border,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
