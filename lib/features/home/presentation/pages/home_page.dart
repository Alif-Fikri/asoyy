import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_bloc.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../alarm/domain/entities/alarm_entity.dart';
import '../../../alarm/presentation/bloc/alarm_bloc.dart';
import '../../../alarm/presentation/bloc/alarm_state.dart';
import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../calendar/presentation/bloc/calendar_state.dart';
import '../../../finance/domain/entities/transaction_entity.dart';
import '../../../finance/presentation/bloc/finance_bloc.dart';
import '../../../finance/presentation/bloc/finance_state.dart';
import '../../../password/presentation/bloc/password_bloc.dart';
import '../../../password/presentation/bloc/password_state.dart';

class HomePage extends StatefulWidget {
  final void Function(int) onNavigate;
  const HomePage({super.key, required this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _userName;
  late Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box(AppConstants.settingsBox);
    _userName =
        _settingsBox.get('user_name', defaultValue: 'Pengguna') as String;
  }

  void _editName(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final ctrl = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          s.edit_name,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: s.enter_name,
            hintStyle: TextStyle(color: c.textHint),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel,
                style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                _settingsBox.put('user_name', name);
                setState(() => _userName = name);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              s.save,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final now = DateTime.now();
    final isId = context.currentLocale.languageCode == 'id';
    final dateFmt = DateFormat('EEEE, d MMMM yyyy', isId ? 'id_ID' : 'en_US');

    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            floating: false,
            pinned: true,
            backgroundColor: c.background,
            actions: [
              _ThemeToggle(),
              const SizedBox(width: 4),
              _LanguageToggle(),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1a0533), c.background]
                        : [const Color(0xFFEDE9FE), c.background],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(now.hour, s),
                      style: TextStyle(color: c.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _userName,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _editName(context),
                          child: Icon(CupertinoIcons.pencil,
                              size: 18, color: c.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(dateFmt.format(now),
                        style: TextStyle(color: c.textHint, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildQuickStats(context, s)),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildActiveAlarms(context, s)),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildUpcomingEvents(context, s)),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _buildRecentTransactions(context, s),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AppStrings s) {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<FinanceBloc, FinanceState>(
            builder: (_, state) {
              final fmt = NumberFormat.compact(locale: 'id_ID');
              double balance = 0;
              if (state is FinanceLoaded) balance = state.balance;
              return _StatCard(
                label: s.home_balance,
                value: 'Rp ${fmt.format(balance)}',
                icon: CupertinoIcons.creditcard,
                color: AppColors.financeColor,
                onTap: () => widget.onNavigate(3),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BlocBuilder<AlarmBloc, AlarmState>(
            builder: (_, state) {
              int active = 0;
              if (state is AlarmLoaded) {
                active = state.alarms.where((a) => a.isEnabled).length;
              }
              return _StatCard(
                label: s.home_active_alarms,
                value: '$active',
                icon: CupertinoIcons.alarm,
                color: AppColors.alarmColor,
                onTap: () => widget.onNavigate(2),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BlocBuilder<PasswordBloc, PasswordState>(
            builder: (_, state) {
              int count = 0;
              if (state is PasswordLoaded) count = state.all.length;
              return _StatCard(
                label: s.home_passwords,
                value: '$count',
                icon: CupertinoIcons.lock,
                color: AppColors.passwordColor,
                onTap: () => widget.onNavigate(4),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveAlarms(BuildContext context, AppStrings s) {
    return BlocBuilder<AlarmBloc, AlarmState>(
      builder: (_, state) {
        if (state is! AlarmLoaded) return const SizedBox();
        final active = state.alarms.where((a) => a.isEnabled).toList();
        if (active.isEmpty) return const SizedBox();

        final dayNames = [
          s.alarm_mon, s.alarm_tue, s.alarm_wed, s.alarm_thu,
          s.alarm_fri, s.alarm_sat, s.alarm_sun,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.home_active_alarms, style: _sectionStyle(context)),
                GestureDetector(
                  onTap: () => widget.onNavigate(2),
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...active.take(3).map(
              (alarm) => _AlarmTile(
                alarm: alarm,
                dayNames: dayNames,
                once: s.alarm_once,
                everyday: s.alarm_everyday,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingEvents(BuildContext context, AppStrings s) {
    final c = context.colors;
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (_, state) {
        if (state is! CalendarLoaded) return const SizedBox();
        final now = DateTime.now();
        final upcoming = state.events
            .where((e) =>
                e.date.isAfter(now) &&
                e.date.isBefore(now.add(const Duration(days: 7))))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (upcoming.isEmpty) return const SizedBox();

        final isId = context.currentLocale.languageCode == 'id';
        final dateFmt = DateFormat('EEE, d MMM', isId ? 'id_ID' : 'en_US');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.home_upcoming, style: _sectionStyle(context)),
            const SizedBox(height: 12),
            ...upcoming.take(3).map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: e.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            dateFmt.format(e.date),
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _DaysBadge(label: _daysUntil(e.date, s), color: e.color),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentTransactions(BuildContext context, AppStrings s) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (_, state) {
        if (state is! FinanceLoaded) return const SizedBox();
        if (state.all.isEmpty) return const SizedBox();

        final sorted = [...state.all]..sort((a, b) => b.date.compareTo(a.date));
        final recent = sorted.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.home_recent_transactions, style: _sectionStyle(context)),
                GestureDetector(
                  onTap: () => widget.onNavigate(3),
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recent.map((tx) => _TransactionTile(transaction: tx)),
          ],
        );
      },
    );
  }

  TextStyle _sectionStyle(BuildContext context) => TextStyle(
        color: context.colors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      );

  String _getGreeting(int hour, AppStrings s) {
    if (hour < 10) return s.greeting_morning;
    if (hour < 15) return s.greeting_afternoon;
    if (hour < 18) return s.greeting_evening;
    return s.greeting_night;
  }

  String _daysUntil(DateTime date, AppStrings s) {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff == 0) return s.home_today;
    if (diff == 1) return s.home_tomorrow;
    return s.days_away(diff);
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.read<ThemeCubit>().state == ThemeMode.dark;
    return IconButton(
      icon: Icon(
        isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
        color: context.colors.textSecondary,
        size: 20,
      ),
      onPressed: () => context.read<ThemeCubit>().toggle(),
      tooltip: isDark ? 'Light Mode' : 'Dark Mode',
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isId = context.read<LocaleBloc>().state.languageCode == 'id';
    return GestureDetector(
      onTap: () => context.read<LocaleBloc>().toggle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isId ? '🇮🇩' : '🇺🇸', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              isId ? 'ID' : 'EN',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmTile extends StatelessWidget {
  final AlarmEntity alarm;
  final List<String> dayNames;
  final String once;
  final String everyday;

  const _AlarmTile({
    required this.alarm,
    required this.dayNames,
    required this.once,
    required this.everyday,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.alarmColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.alarmColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.alarm,
                color: AppColors.alarmColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm.timeString,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alarm.label.isNotEmpty
                      ? '${alarm.label} · ${alarm.daysString(dayNames, once, everyday)}'
                      : alarm.daysString(dayNames, once, everyday),
                  style:
                      TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.alarmColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ON',
              style: TextStyle(
                color: AppColors.alarmColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('d MMM', 'id_ID');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${transaction.category} · ${dateFmt.format(transaction.date)}',
                  style:
                      TextStyle(color: c.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${fmt.format(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DaysBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: c.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
