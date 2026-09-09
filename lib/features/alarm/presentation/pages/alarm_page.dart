import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../bloc/alarm_bloc.dart';
import '../bloc/alarm_event.dart';
import '../bloc/alarm_state.dart';
import '../widgets/alarm_card.dart';
import '../widgets/alarm_form_dialog.dart';

class AlarmPage extends StatelessWidget {
  const AlarmPage({super.key});

  void _showAddAlarm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AlarmFormDialog(
        onSave: (alarm) => context.read<AlarmBloc>().add(
              AddAlarmRequested(alarm, stopButtonText: context.strings.alarm_stop),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<AlarmBloc, AlarmState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: c.background,
          appBar: NexusAppBar(
            title: context.strings.alarm_title,
            showLanguageToggle: true,
            extraActions: [
              IconButton(
                icon: const Icon(CupertinoIcons.plus_circle),
                onPressed: () => _showAddAlarm(context),
                tooltip: context.strings.alarm_add,
              ),
            ],
          ),
          body: SafeArea(child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AlarmState state) {
    final s = context.strings;

    if (state is AlarmLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is AlarmError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: AppColors.alarmColor),
        ),
      );
    }
    if (state is AlarmLoaded) {
      if (state.alarms.isEmpty) {
        return EmptyStateWidget(
          icon: CupertinoIcons.alarm,
          title: s.alarm_empty_title,
          subtitle: s.alarm_empty_subtitle,
        );
      }

      final active = state.alarms.where((a) => a.isEnabled).toList();
      final disabled = state.alarms.where((a) => !a.isEnabled).toList();

      return ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          8,
          0,
          MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          if (active.isNotEmpty)
            IosSection(
              header: s.alarm_title,
              children: active
                  .map(
                    (a) => AlarmCard(
                      alarm: a,
                      onToggle: (enabled) => context.read<AlarmBloc>().add(
                        ToggleAlarmRequested(
                          a.copyWith(isEnabled: enabled),
                          stopButtonText: context.strings.alarm_stop,
                        ),
                      ),
                      onDelete: () => context
                          .read<AlarmBloc>()
                          .add(DeleteAlarmRequested(a.id)),
                    ),
                  )
                  .toList(),
            ),
          if (disabled.isNotEmpty)
            IosSection(
              header: s.alarm_disabled,
              children: disabled
                  .map(
                    (a) => AlarmCard(
                      alarm: a,
                      onToggle: (enabled) => context.read<AlarmBloc>().add(
                        ToggleAlarmRequested(
                          a.copyWith(isEnabled: enabled),
                          stopButtonText: context.strings.alarm_stop,
                        ),
                      ),
                      onDelete: () => context
                          .read<AlarmBloc>()
                          .add(DeleteAlarmRequested(a.id)),
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
