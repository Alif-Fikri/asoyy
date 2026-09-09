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
import '../../../alarm/presentation/bloc/alarm_state.dart';
import '../../../alarm/presentation/pages/alarm_page.dart';
import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../calendar/presentation/bloc/calendar_state.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../domain/reminder_item.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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
                now: now,
                alarmColor: AppColors.alarmColor,
                holidayColor: AppColors.calendarColor,
                paydayColor: AppColors.income,
                paydayLabel: s.cal_payday,
                isId: isId,
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
                            .map((item) => _ReminderRow(item: item, isId: isId))
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

class _ReminderRow extends StatelessWidget {
  final ReminderItem item;
  final bool isId;

  const _ReminderRow({required this.item, required this.isId});

  IconData get _icon => switch (item.kind) {
        ReminderKind.alarm => CupertinoIcons.alarm,
        ReminderKind.event => CupertinoIcons.calendar,
        ReminderKind.holiday => CupertinoIcons.flag,
        ReminderKind.payday => CupertinoIcons.money_dollar_circle,
      };

  String _kindLabel(AppStrings s) => switch (item.kind) {
        ReminderKind.alarm => s.notif_kind_alarm,
        ReminderKind.event => s.notif_kind_event,
        ReminderKind.holiday => s.notif_kind_holiday,
        ReminderKind.payday => s.notif_kind_payday,
      };

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final locale = isId ? 'id_ID' : 'en_US';
    final pattern = item.hasTime ? 'EEE, d MMM · HH:mm' : 'EEE, d MMM';
    final subtitle =
        '${_kindLabel(s)} · ${DateFormat(pattern, locale).format(item.when)}';

    return IosRow(
      leading: IosIcon(icon: _icon, color: item.color),
      title: item.title,
      subtitle: subtitle,
      showChevron: true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => item.kind == ReminderKind.alarm
              ? const AlarmPage()
              : const CalendarPage(),
        ),
      ),
    );
  }
}
