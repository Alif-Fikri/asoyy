import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/name_prefs.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/menu_icon.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../../core/widgets/toggle_controls.dart';
import '../../../finance/presentation/bloc/finance_bloc.dart';
import '../../../finance/presentation/bloc/finance_state.dart';
import '../../../finance/presentation/widgets/finance_export_dialog.dart';
import '../../../password/data/auth_config_repository.dart';
import '../../../password/presentation/password_actions.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthConfigRepository _authRepo = AuthConfigRepository();
  late String _userName = readUserName();

  Future<void> _editName() async {
    final name = await showEditNameDialog(context);
    if (name != null && mounted) setState(() => _userName = name);
  }

  void _exportFinance() {
    final state = context.read<FinanceBloc>().state;
    if (state is! FinanceLoaded) return;
    showFinanceExportSheet(context, state.all);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.nav_profile),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          16,
          0,
          MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          _ProfileHeader(name: _userName),
          const SizedBox(height: 24),
          IosSection(
            header: s.profile_account,
            children: [
              IosRow(
                leading: const MenuIconImage(
                  asset: 'assets/images/menu_person.png',
                  size: Sizes.iconTile,
                ),
                title: s.profile_name,
                subtitle: _userName,
                showChevron: true,
                onTap: _editName,
              ),
            ],
          ),
          IosSection(
            header: s.profile_appearance,
            children: [
              IosRow(
                leading: const MenuIconImage(
                  asset: 'assets/images/menu_theme.png',
                  size: Sizes.iconTile,
                ),
                title: s.profile_theme,
                trailing: const ThemeToggleButton(),
              ),
              IosRow(
                leading: const MenuIconImage(
                  asset: 'assets/images/menu_language.png',
                  size: Sizes.iconTile,
                ),
                title: s.profile_language,
                trailing: const LanguageToggleChip(),
              ),
            ],
          ),
          IosSection(
            header: s.profile_security,
            children: [
              IosRow(
                leading: const MenuIconImage(
                  asset: 'assets/images/menu_security.png',
                  size: Sizes.iconTile,
                ),
                title: s.auth_change_method,
                showChevron: true,
                onTap: () => changeAuthMethod(context, _authRepo),
              ),
            ],
          ),
          IosSection(
            header: s.profile_data,
            children: [
              IosRow(
                leading: const MenuIconImage(
                  asset: 'assets/images/menu_finance.png',
                  size: Sizes.iconTile,
                ),
                title: s.profile_export_finance,
                showChevron: true,
                onTap: _exportFinance,
              ),
              IosRow(
                leading: const MenuIconImage(
                  asset: 'assets/images/menu_download.png',
                  size: Sizes.iconTile,
                ),
                title: s.profile_export_password,
                showChevron: true,
                onTap: () => exportPasswordsCsv(context, _authRepo),
              ),
              IosRow(
                leading: const MenuIconImage(
                  asset: 'assets/images/menu_upload.png',
                  size: Sizes.iconTile,
                ),
                title: s.profile_import_password,
                showChevron: true,
                onTap: () => importPasswordsCsv(context, _authRepo),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;

  const _ProfileHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
