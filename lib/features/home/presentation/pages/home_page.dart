import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/utils/name_prefs.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../alarm/presentation/bloc/alarm_bloc.dart';
import '../../../alarm/presentation/bloc/alarm_state.dart';
import '../../../alarm/presentation/pages/alarm_page.dart';
import '../../../calculator/presentation/pages/calculator_page.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../finance/presentation/bloc/finance_bloc.dart';
import '../../../finance/presentation/bloc/finance_state.dart';
import '../../../finance/presentation/pages/finance_page.dart';
import '../../../password/presentation/bloc/password_bloc.dart';
import '../../../password/presentation/bloc/password_state.dart';
import '../../../password/presentation/pages/password_flow_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final now = DateTime.now();
    final isId = context.currentLocale.languageCode == 'id';
    final dateFmt = DateFormat('EEEE, d MMMM yyyy', isId ? 'id_ID' : 'en_US');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: c.background,
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
                      _greeting(now.hour, s),
                      style: TextStyle(color: c.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      readUserName(),
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFmt.format(now),
                      style: TextStyle(color: c.textHint, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverToBoxAdapter(child: _QuickStats()),
          ),
          SliverToBoxAdapter(child: _FeatureMenu()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _greeting(int hour, AppStrings s) {
    if (hour < 10) return s.greeting_morning;
    if (hour < 15) return s.greeting_afternoon;
    if (hour < 18) return s.greeting_evening;
    return s.greeting_night;
  }
}

void openFeature(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class _QuickStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<FinanceBloc, FinanceState>(
            builder: (_, state) {
              final fmt = NumberFormat.compact(locale: 'id_ID');
              final balance = state is FinanceLoaded ? state.balance : 0.0;
              return _StatCard(
                label: s.home_balance,
                value: 'Rp ${fmt.format(balance)}',
                icon: CupertinoIcons.creditcard,
                color: AppColors.financeColor,
                onTap: () => openFeature(context, const FinancePage()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BlocBuilder<AlarmBloc, AlarmState>(
            builder: (_, state) {
              final active = state is AlarmLoaded
                  ? state.alarms.where((a) => a.isEnabled).length
                  : 0;
              return _StatCard(
                label: s.home_active_alarms,
                value: '$active',
                icon: CupertinoIcons.alarm,
                color: AppColors.alarmColor,
                onTap: () => openFeature(context, const AlarmPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BlocBuilder<PasswordBloc, PasswordState>(
            builder: (_, state) {
              final count = state is PasswordLoaded ? state.all.length : 0;
              return _StatCard(
                label: s.home_passwords,
                value: '$count',
                icon: CupertinoIcons.lock,
                color: AppColors.passwordColor,
                onTap: () => openFeature(context, const PasswordFlowPage()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeatureMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return IosSection(
      header: s.home_features,
      children: [
        IosRow(
          leading: const IosIcon(
            icon: CupertinoIcons.calendar,
            color: AppColors.calendarColor,
          ),
          title: s.nav_calendar,
          showChevron: true,
          onTap: () => openFeature(context, const CalendarPage()),
        ),
        IosRow(
          leading: const IosIcon(
            icon: CupertinoIcons.alarm,
            color: AppColors.alarmColor,
          ),
          title: s.nav_alarm,
          showChevron: true,
          onTap: () => openFeature(context, const AlarmPage()),
        ),
        IosRow(
          leading: const IosIcon(
            icon: CupertinoIcons.plus_slash_minus,
            color: AppColors.calculatorColor,
          ),
          title: s.calc_title,
          showChevron: true,
          onTap: () => openFeature(context, const CalculatorPage()),
        ),
        IosRow(
          leading: const IosIcon(
            icon: CupertinoIcons.creditcard,
            color: AppColors.financeColor,
          ),
          title: s.nav_finance,
          showChevron: true,
          onTap: () => openFeature(context, const FinancePage()),
        ),
        IosRow(
          leading: const IosIcon(
            icon: CupertinoIcons.lock,
            color: AppColors.passwordColor,
          ),
          title: s.nav_password,
          showChevron: true,
          onTap: () => openFeature(context, const PasswordFlowPage()),
        ),
      ],
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
          Text(label, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
