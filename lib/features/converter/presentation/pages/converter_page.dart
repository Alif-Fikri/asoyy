import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../widgets/currency_converter_tab.dart';
import '../widgets/unit_converter_tab.dart';

class ConverterPage extends StatelessWidget {
  const ConverterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: NexusAppBar(
          title: s.convert_title,
          showLanguageToggle: true,
        ),
        body: Column(
          children: [
            TabBar(
              labelColor: c.textPrimary,
              unselectedLabelColor: c.textSecondary,
              indicatorColor: c.textPrimary,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: s.convert_units),
                Tab(text: s.convert_currency),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  UnitConverterTab(),
                  CurrencyConverterTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
