import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../domain/entities/alarm_entity.dart';

class AlarmCard extends StatelessWidget {
  final AlarmEntity alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final dayNames = [
      s.alarm_mon,
      s.alarm_tue,
      s.alarm_wed,
      s.alarm_thu,
      s.alarm_fri,
      s.alarm_sat,
      s.alarm_sun,
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () async {
          final confirmed = await showDeleteConfirm(context);
          if (confirmed) onDelete();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: Sizes.rowMinHeight),
          padding: const EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.md,
            Insets.sm,
            Insets.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: alarm.isEnabled ? 1.0 : 0.45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm.timeString,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alarm.label.isNotEmpty
                            ? '${alarm.label} · ${alarm.daysString(dayNames, s.alarm_once, s.alarm_everyday)}'
                            : alarm.daysString(
                              dayNames,
                              s.alarm_once,
                              s.alarm_everyday,
                            ),
                        style: AppType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              Switch(
                value: alarm.isEnabled,
                onChanged: onToggle,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
