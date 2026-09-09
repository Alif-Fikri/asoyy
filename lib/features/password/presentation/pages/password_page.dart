import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../data/auth_config_repository.dart';
import '../../domain/entities/password_entity.dart';
import '../password_actions.dart';
import '../bloc/password_bloc.dart';
import '../bloc/password_event.dart';
import '../bloc/password_state.dart';
import '../widgets/password_card.dart';
import '../widgets/password_form_dialog.dart';

class PasswordPage extends StatefulWidget {
  final AuthConfigRepository authRepo;
  const PasswordPage({super.key, required this.authRepo});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  void _showForm(BuildContext context, {PasswordEntity? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PasswordFormDialog(
        existing: existing,
        onSave: (p) =>
            context.read<PasswordBloc>().add(SavePasswordRequested(p)),
      ),
    );
  }

  Future<void> _changeAuthMethod() async {
    await changeAuthMethod(context, widget.authRepo);
    if (mounted) setState(() {});
  }

  Future<void> _exportCsv() => exportPasswordsCsv(context, widget.authRepo);

  Future<void> _importCsv() => importPasswordsCsv(context, widget.authRepo);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    return BlocBuilder<PasswordBloc, PasswordState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: c.background,
          appBar: NexusAppBar(
            title: s.pass_title,
            showLanguageToggle: true,
            extraActions: [
              IconButton(
                icon: const Icon(CupertinoIcons.shield),
                onPressed: _changeAuthMethod,
                tooltip: s.auth_change_method,
              ),
              PopupMenuButton<String>(
                icon: const Icon(CupertinoIcons.ellipsis_vertical),
                onSelected: (value) {
                  if (value == 'export') _exportCsv();
                  if (value == 'import') _importCsv();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(children: [
                      const Icon(CupertinoIcons.arrow_down_to_line, size: 18),
                      const SizedBox(width: 10),
                      Text(s.pass_export),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'import',
                    child: Row(children: [
                      const Icon(CupertinoIcons.arrow_up_circle, size: 18),
                      const SizedBox(width: 10),
                      Text(s.pass_import),
                    ]),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.plus_circle),
                onPressed: () => _showForm(context),
                tooltip: s.pass_add,
              ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PasswordState state) {
    final s = context.strings;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    if (state is PasswordLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is PasswordError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: AppColors.alarmColor),
        ),
      );
    }
    if (state is PasswordLoaded) {
      final items = state.filtered;
      return ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          8,
          0,
          MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          _SearchBar(
            onChanged: (q) =>
                context.read<PasswordBloc>().add(SearchPasswords(q)),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: EmptyStateWidget(
                icon: CupertinoIcons.lock,
                title: state.query.isEmpty
                    ? s.pass_empty_title
                    : s.pass_not_found,
                subtitle: state.query.isEmpty ? s.pass_empty_subtitle : '',
              ),
            )
          else
            IosSection(
              header: isId ? 'Tersimpan' : 'Saved',
              footer: isId
                  ? 'Ketuk untuk menampilkan password. Tekan lama untuk menghapus.'
                  : 'Tap to reveal password. Long-press to delete.',
              children: items
                  .map(
                    (p) => PasswordCard(
                      password: p,
                      onEdit: () => _showForm(context, existing: p),
                      onDelete: () => context
                          .read<PasswordBloc>()
                          .add(DeletePasswordRequested(p.id)),
                    ),
                  )
                  .toList(),
            ),
        ],
      );
    }
    return const SizedBox();
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: c.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: context.strings.pass_search_hint,
          hintStyle: TextStyle(color: c.textHint, fontSize: 15),
          prefixIcon: Icon(CupertinoIcons.search, color: c.textSecondary, size: 18),
          filled: true,
          fillColor: c.cardLight,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
