import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/name_prefs.dart';
import '../../../../core/widgets/menu_icon.dart';
import '../../../alarm/presentation/pages/alarm_page.dart';
import '../../../calculator/presentation/pages/calculator_page.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../converter/presentation/pages/converter_page.dart';
import '../../../finance/presentation/bloc/finance_bloc.dart';
import '../../../finance/presentation/bloc/finance_state.dart';
import '../../../finance/presentation/pages/finance_page.dart';
import '../../../password/presentation/pages/password_flow_page.dart';
import '../../../search/presentation/pages/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  double _titleOpacity = 0;

  static const _collapseRange = 60.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final opacity = (_scrollController.offset / _collapseRange).clamp(0.0, 1.0);
    if (opacity != _titleOpacity) {
      setState(() => _titleOpacity = opacity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final now = DateTime.now();
    final isId = context.currentLocale.languageCode == 'id';
    final dateFmt = DateFormat('EEEE, d MMMM yyyy', isId ? 'id_ID' : 'en_US');

    return Scaffold(
      backgroundColor: c.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 132,
            pinned: true,
            backgroundColor: c.background,
            title: Opacity(
              opacity: _titleOpacity,
              child: Text(
                readUserName(),
                style: AppType.title.copyWith(color: c.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  0,
                  Insets.lg,
                  Insets.lg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(now.hour, s),
                      style: AppType.caption.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: Insets.xs),
                    Text(
                      readUserName(),
                      style: AppType.display.copyWith(color: c.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFmt.format(now),
                      style: AppType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.sm,
              Insets.lg,
              Insets.xl,
            ),
            sliver: SliverToBoxAdapter(child: _SearchBar(s: s)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, 0),
            sliver: SliverToBoxAdapter(child: _BalanceCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.xl,
              Insets.lg,
              Insets.xxl,
            ),
            sliver: SliverToBoxAdapter(child: _FeatureMenu()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Insets.xxl)),
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

class _SearchBar extends StatelessWidget {
  final AppStrings s;

  const _SearchBar({required this.s});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => openFeature(context, const SearchPage()),
        child: Container(
          height: Sizes.fieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: Insets.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.search,
                color: c.textSecondary,
                size: Sizes.icon,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  s.search_hint,
                  style: AppType.body.copyWith(color: c.textHint),
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

class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        final loaded = state is FinanceLoaded ? state : null;
        final balance = loaded?.balance ?? 0;
        final income = loaded?.totalIncome ?? 0;
        final expense = loaded?.totalExpense ?? 0;
        final fmt = NumberFormat.decimalPattern('id_ID');

        return Material(
          color: c.card,
          borderRadius: BorderRadius.circular(Radii.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.lg),
            onTap: () => openFeature(context, const FinancePage()),
            child: Container(
              padding: const EdgeInsets.all(Insets.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.home_balance.toUpperCase(),
                    style: AppType.label.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: Insets.sm),
                  Text(
                    'Rp ${fmt.format(balance)}',
                    style: AppType.display.copyWith(
                      color: balance < 0 ? AppColors.expense : c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Insets.lg),
                  Container(height: 0.5, color: c.divider),
                  const SizedBox(height: Insets.md),
                  Row(
                    children: [
                      Expanded(
                        child: _FlowStat(
                          icon: CupertinoIcons.arrow_down_left,
                          label: s.fin_income,
                          value: 'Rp ${fmt.format(income)}',
                          color: AppColors.income,
                        ),
                      ),
                      Expanded(
                        child: _FlowStat(
                          icon: CupertinoIcons.arrow_up_right,
                          label: s.fin_expense,
                          value: 'Rp ${fmt.format(expense)}',
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlowStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _FlowStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: Sizes.iconSm, color: color),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppType.caption.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: AppType.body.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Insets.xs, 0, Insets.xs, Insets.md),
          child: Text(
            s.home_features.toUpperCase(),
            style: AppType.label.copyWith(color: c.textSecondary),
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Insets.md,
          crossAxisSpacing: Insets.md,
          childAspectRatio: 1.12,
          children: items.map((item) => _MenuTile(item: item)).toList(),
        ),
      ],
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
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(Insets.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MenuIconImage(asset: item.asset, size: Sizes.menuIcon),
              const SizedBox(height: Insets.sm),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: AppType.caption.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
