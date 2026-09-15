import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/resizable_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../domain/entities/note_entity.dart';

class NoteFormPage extends StatefulWidget {
  final NoteEntity? existing;
  final void Function(NoteEntity) onSave;

  const NoteFormPage({super.key, this.existing, required this.onSave});

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _itemCtrl = TextEditingController();

  List<ChecklistItem> _items = [];
  DateTime? _dueDate;
  DateTime? _remindAt;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;
    _titleCtrl.text = existing.title;
    _bodyCtrl.text = existing.body ?? '';
    _items = [...existing.items];
    _dueDate = existing.dueDate;
    _remindAt = existing.remindAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _itemCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _itemCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items = [
        ..._items,
        ChecklistItem(id: const Uuid().v4(), text: text),
      ];
      _itemCtrl.clear();
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _remindAt ?? _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_remindAt ?? now),
    );
    if (time == null || !mounted) return;

    final at = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!at.isAfter(DateTime.now())) {
      AppToast.show(context, context.strings.notes_reminder_past);
      return;
    }
    setState(() => _remindAt = at);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final body = _bodyCtrl.text.trim();

    widget.onSave(NoteEntity(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      body: body.isEmpty ? null : body,
      items: _items,
      dueDate: _dueDate,
      remindAt: _remindAt,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      isDone: widget.existing?.isDone ?? false,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final dateFmt = DateFormat('d MMM yyyy', isId ? 'id_ID' : 'en_US');
    final timeFmt = DateFormat('d MMM yyyy HH:mm', isId ? 'id_ID' : 'en_US');

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(
        title: widget.existing == null ? s.notes_add : s.notes_edit,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(Insets.lg),
            children: [
              AppTextField(
                label: s.notes_note_title,
                controller: _titleCtrl,
                prefixIcon: CupertinoIcons.textformat,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.required_field : null,
              ),
              const SizedBox(height: Insets.md),
              ResizableTextField(
                label: s.notes_body,
                controller: _bodyCtrl,
                prefixIcon: CupertinoIcons.text_alignleft,
              ),
              const SizedBox(height: Insets.xl),
              Text(
                s.notes_checklist.toUpperCase(),
                style: AppType.label.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: Insets.sm),
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: Insets.xs),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.square,
                          size: 18, color: c.textSecondary),
                      const SizedBox(width: Insets.sm),
                      Expanded(
                        child: Text(
                          item.text,
                          style: AppType.body.copyWith(color: c.textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark,
                            size: 16, color: c.textHint),
                        onPressed: () => setState(
                          () => _items =
                              _items.where((i) => i.id != item.id).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: s.notes_add_item,
                      controller: _itemCtrl,
                      prefixIcon: CupertinoIcons.plus,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.plus_circle_fill,
                        color: AppColors.primary),
                    onPressed: _addItem,
                  ),
                ],
              ),
              const SizedBox(height: Insets.xl),
              _PickerRow(
                icon: CupertinoIcons.calendar,
                label: s.notes_deadline,
                value: _dueDate == null
                    ? s.notes_deadline_none
                    : dateFmt.format(_dueDate!),
                onTap: _pickDeadline,
                onClear: _dueDate == null
                    ? null
                    : () => setState(() => _dueDate = null),
              ),
              const SizedBox(height: Insets.sm),
              _PickerRow(
                icon: CupertinoIcons.bell,
                label: s.notes_reminder,
                value: _remindAt == null
                    ? s.notes_reminder_none
                    : timeFmt.format(_remindAt!),
                onTap: _pickReminder,
                onClear: _remindAt == null
                    ? null
                    : () => setState(() => _remindAt = null),
              ),
              const SizedBox(height: Insets.sm),
              Text(
                s.notes_reminder_optional,
                style: AppType.caption
                    .copyWith(color: c.textSecondary, height: 1.4),
              ),
              const SizedBox(height: Insets.xxl),
              AppButton(
                label: s.save,
                onTap: _submit,
                width: double.infinity,
                icon: CupertinoIcons.check_mark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.md,
        ),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.textSecondary),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Text(
                label,
                style: AppType.body.copyWith(color: c.textPrimary),
              ),
            ),
            Text(
              value,
              style: AppType.caption.copyWith(color: c.textSecondary),
            ),
            if (onClear != null)
              IconButton(
                icon: Icon(CupertinoIcons.xmark_circle_fill,
                    size: 16, color: c.textHint),
                onPressed: onClear,
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: Insets.xs),
                child: Icon(CupertinoIcons.chevron_right,
                    size: 16, color: c.textHint),
              ),
          ],
        ),
      ),
    );
  }
}
