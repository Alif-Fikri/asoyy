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
import '../../../../core/widgets/menu_icon.dart';
import '../../../alarm/presentation/bloc/alarm_bloc.dart';
import '../../../alarm/presentation/bloc/alarm_state.dart';
import '../../../alarm/presentation/pages/alarm_page.dart';
import '../../../calculator/presentation/pages/calculator_page.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../converter/presentation/pages/converter_page.dart';
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
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                bottom: 16,
              ),
              title: Text(
                '${_greeting(now.hour, s)}, ${readUserName()}',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
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
    final items = [
      _MenuItemData(
        asset: 'assets/images/menu_calendar.png',
        label: s.nav_calendar,
        onTap: () => openFeature(context, const CalendarPage()),
      ),
      _MenuItemData(
        asset: 'assets/images/menu_alarm.png',
        label: s.nav_alarm,
        onTap: () => openFeature(context, const AlarmPage()),
      ),
      _MenuItemData(
        asset: 'assets/images/menu_calculator.png',
        label: s.calc_title,
        onTap: () => openFeature(context, const CalculatorPage()),
      ),
      _MenuItemData(
        asset: 'assets/images/menu_converter.png',
        label: s.convert_title,
        onTap: () => openFeature(context, const ConverterPage()),
      ),
      _MenuItemData(
        asset: 'assets/images/menu_finance.png',
        label: s.nav_finance,
        onTap: () => openFeature(context, const FinancePage()),
      ),
      _MenuItemData(
        asset: 'assets/images/menu_password.png',
        label: s.nav_password,
        onTap: () => openFeature(context, const PasswordFlowPage()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              s.home_features.toUpperCase(),
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.9,
            children: items.map((item) => _MenuTile(item: item)).toList(),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final String asset;
  final String label;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.asset,
    required this.label,
    required this.onTap,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItemData item;

  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              MenuIconImage(asset: item.asset, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
          Text(label, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
