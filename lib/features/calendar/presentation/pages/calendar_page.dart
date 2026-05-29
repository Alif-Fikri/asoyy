import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/utils/hijri_converter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/holiday_entity.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../widgets/event_form_dialog.dart';
import '../widgets/event_list_item.dart';
import '../widgets/holiday_list_item.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  void _showAddEvent(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFormDialog(
        initialDate: date,
        onSave: (event) =>
            context.read<CalendarBloc>().add(AddEventRequested(event)),
      ),
    );
  }

  void _showPaydaySettings(BuildContext context, int? currentDay) {
    final s = context.strings;
    final c = context.colors;
    final ctrl = TextEditingController(
      text: currentDay != null ? '$currentDay' : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.cal_payday_settings,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.cal_payday_day_label,
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                style: TextStyle(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: s.cal_payday_hint,
                  prefixIcon: Icon(
                    CupertinoIcons.money_dollar_circle,
                    color: c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (currentDay != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<CalendarBloc>().add(SetPayday(null));
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.alarmColor,
                          side: BorderSide(
                            color:
                                AppColors.alarmColor.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(s.cal_payday_clear),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final val = int.tryParse(ctrl.text);
                        if (val != null && val >= 1 && val <= 31) {
                          context.read<CalendarBloc>().add(SetPayday(val));
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.income,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(s.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state is CalendarLoading) {
          return Scaffold(
            backgroundColor: c.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is CalendarError) {
          return Scaffold(
            backgroundColor: c.background,
            body: Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.alarmColor),
              ),
            ),
          );
        }
        if (state is! CalendarLoaded) return const SizedBox();

        final s = context.strings;
        final events = state.eventsForSelectedDay;
        final holidays = state.holidaysForSelectedDay;
        final hasPayday = state.isPaydaySelected;

        return Scaffold(
          backgroundColor: c.background,
          appBar: NexusAppBar(
            title: s.cal_title,
            showLanguageToggle: true,
            extraActions: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.money_dollar_circle,
                  color: state.paydayDay != null
                      ? AppColors.income
                      : c.textSecondary,
                  size: 22,
                ),
                onPressed: () =>
                    _showPaydaySettings(context, state.paydayDay),
                tooltip: s.cal_payday_settings,
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.plus_circle),
                onPressed: () => _showAddEvent(context, state.selectedDay),
                tooltip: s.cal_add_event,
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              8,
              0,
              MediaQuery.of(context).padding.bottom + 80,
            ),
            children: [

              IosSection(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [_buildCalendar(context, state)],
              ),


              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _buildLegend(context, s),
              ),


              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: _buildDayHeader(context, state),
              ),

              if (events.isEmpty && holidays.isEmpty && !hasPayday)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: EmptyStateWidget(
                    icon: CupertinoIcons.calendar,
                    title: s.cal_empty_title,
                    subtitle: s.cal_empty_subtitle,
                  ),
                )
              else
                IosSection(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (hasPayday) const PaydayListItem(),
                    ...holidays.map((h) => HolidayListItem(holiday: h)),
                    ...events.map(
                      (e) => EventListItem(
                        event: e,
                        onDelete: () => context
                            .read<CalendarBloc>()
                            .add(DeleteEventRequested(e.id)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendar(BuildContext context, CalendarLoaded state) {
    final c = context.colors;
    final isId = context.currentLocale.languageCode == 'id';
    final eventMap = state.eventMap;
    final holidayMap = state.holidayMap;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: state.focusedDay,
        locale: isId ? 'id_ID' : 'en_US',
        rowHeight: 48,
        selectedDayPredicate: (d) => isSameDay(d, state.selectedDay),
        eventLoader: (day) {
          final key = DateTime(day.year, day.month, day.day);
          final result = <dynamic>[];
          result.addAll(eventMap[key] ?? []);
          result.addAll(holidayMap[key] ?? []);
          if (state.paydayDay != null && day.day == state.paydayDay) {
            result.add(const PaydayMarker());
          }
          return result;
        },
        onDaySelected: (selected, focused) =>
            context.read<CalendarBloc>().add(SelectDay(selected)),
        calendarBuilders: CalendarBuilders(
          markerBuilder:
              (ctx, day, events) => _buildMarkers(ctx, day, events, c),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,


          defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
          weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
          outsideDecoration: const BoxDecoration(shape: BoxShape.circle),
          disabledDecoration: const BoxDecoration(shape: BoxShape.circle),
          holidayDecoration: const BoxDecoration(shape: BoxShape.circle),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(color: c.textPrimary, fontSize: 14),
          weekendTextStyle: TextStyle(color: c.textSecondary, fontSize: 14),
          todayTextStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          outsideTextStyle: TextStyle(color: c.textHint, fontSize: 14),
          disabledTextStyle: TextStyle(color: c.textHint, fontSize: 14),
          markerDecoration: const BoxDecoration(color: Colors.transparent),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: c.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: Icon(CupertinoIcons.chevron_left, color: c.textSecondary, size: 20),
          rightChevronIcon:
              Icon(CupertinoIcons.chevron_right, color: c.textSecondary, size: 20),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: c.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          weekendStyle: TextStyle(
            color: c.textHint,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget? _buildMarkers(
    BuildContext context,
    DateTime day,
    List<dynamic> events,
    AppColorTheme c,
  ) {
    if (events.isEmpty) return null;

    final dots = <Color>{};
    for (final e in events) {
      if (e is HolidayEntity) {
        dots.add(
          e.isNational ? AppColors.alarmColor : AppColors.calendarColor,
        );
      } else if (e is EventEntity) {
        dots.add(AppColors.primary);
      } else if (e is PaydayMarker) {
        dots.add(AppColors.income);
      }
    }

    if (dots.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: dots
            .map(
              (color) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, dynamic s) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _LegendItem(
          color: AppColors.alarmColor,
          label: s.cal_holiday_national,
        ),
        _LegendItem(color: AppColors.calendarColor, label: s.cal_cuti_bersama),
        _LegendItem(color: AppColors.income, label: s.cal_payday),
        _LegendItem(color: AppColors.primary, label: s.cal_event),
      ],
    );
  }

  Widget _buildDayHeader(BuildContext context, CalendarLoaded state) {
    final c = context.colors;
    final isId = context.currentLocale.languageCode == 'id';
    final fmt = DateFormat('EEEE, d MMMM yyyy', isId ? 'id_ID' : 'en_US');
    final hijri = HijriDate.fromGregorian(state.selectedDay);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fmt.format(state.selectedDay).toUpperCase(),
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hijri.toFullString(),
                style: TextStyle(color: c.textHint, fontSize: 11),
              ),
            ],
          ),
        ),
        if (state.eventsForSelectedDay.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${state.eventsForSelectedDay.length} ${context.strings.cal_event}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: context.colors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
