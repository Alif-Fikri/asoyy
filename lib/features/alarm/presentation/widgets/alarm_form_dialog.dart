import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/alarm_entity.dart';

class AlarmFormDialog extends StatefulWidget {
  final void Function(AlarmEntity) onSave;

  const AlarmFormDialog({super.key, required this.onSave});

  @override
  State<AlarmFormDialog> createState() => _AlarmFormDialogState();
}

class _AlarmFormDialogState extends State<AlarmFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController(text: 'Alarm');
  TimeOfDay _time = TimeOfDay.now();
  final Set<int> _selectedDays = {};

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(AlarmEntity(
      id: const Uuid().v4(),
      label: _labelCtrl.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      days: _selectedDays.toList()..sort(),
      isEnabled: true,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final dayNames = [
      s.alarm_mon, s.alarm_tue, s.alarm_wed, s.alarm_thu,
      s.alarm_fri, s.alarm_sat, s.alarm_sun,
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.alarm_add,
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.alarmColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.alarmColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _time.format(context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.alarmColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: s.alarm_label,
              controller: _labelCtrl,
              prefixIcon: CupertinoIcons.tag,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.required_field : null,
            ),
            const SizedBox(height: 16),
            Text(s.alarm_repeat, style: TextStyle(color: c.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = _selectedDays.contains(day);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.alarmColor
                          : c.cardLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.alarmColor
                            : c.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dayNames[i],
                        style: TextStyle(
                          color: selected
                              ? c.textPrimary
                              : c.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: s.alarm_save,
              onTap: _submit,
              width: double.infinity,
              color: AppColors.alarmColor,
              icon: CupertinoIcons.alarm,
            ),
          ],
        ),
      ),
    );
  }
}
