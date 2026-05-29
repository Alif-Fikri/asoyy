import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/feature_icon.dart';
import '../../domain/entities/event_entity.dart';

class EventFormDialog extends StatefulWidget {
  final DateTime initialDate;
  final void Function(EventEntity) onSave;

  const EventFormDialog({
    super.key,
    required this.initialDate,
    required this.onSave,
  });

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _selectedColorIndex = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(EventEntity(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      date: widget.initialDate,
      colorValue: AppColors.eventColors[_selectedColorIndex].toARGB32(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.cal_add_event,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: s.cal_event_title,
              hint: 'Masukkan judul...',
              controller: _titleCtrl,
              prefixIcon: CupertinoIcons.calendar,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.required_field : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: '${s.cal_description} (${s.optional})',
              hint: 'Tambahkan deskripsi...',
              controller: _descCtrl,
              prefixIcon: CupertinoIcons.doc_text,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text(
              s.cal_color,
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(AppColors.eventColors.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: ColorDot(
                      color: AppColors.eventColors[i],
                      isSelected: _selectedColorIndex == i,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: s.cal_save_event,
              onTap: _submit,
              width: double.infinity,
              icon: CupertinoIcons.check_mark,
            ),
          ],
        ),
      ),
    );
  }
}
