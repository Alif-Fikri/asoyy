import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/utils/note_status.dart';

Color urgencyColor(NoteUrgency urgency) {
  switch (urgency) {
    case NoteUrgency.overdue:
      return AppColors.expense;
    case NoteUrgency.dueToday:
      return AppColors.calendarColor;
    case NoteUrgency.upcoming:
    case NoteUrgency.none:
      return AppColors.primary;
  }
}

String deadlineLabel(NoteEntity note, DateTime now, AppStrings s, bool isId) {
  final due = note.dueDate;
  if (due == null) return '';
  switch (urgencyOf(note, now)) {
    case NoteUrgency.overdue:
      return s.notes_overdue;
    case NoteUrgency.dueToday:
      return s.notes_due_today;
    case NoteUrgency.upcoming:
      final days = daysUntilDue(note, now);
      if (days <= 7) return s.notes_due_in(days);
      return DateFormat('d MMM', isId ? 'id_ID' : 'en_US').format(due);
    case NoteUrgency.none:
      return DateFormat('d MMM', isId ? 'id_ID' : 'en_US').format(due);
  }
}

class NoteCard extends StatelessWidget {
  final NoteEntity note;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;
  final void Function(String itemId) onToggleItem;

  const NoteCard({
    super.key,
    required this.note,
    required this.now,
    required this.onTap,
    required this.onToggleDone,
    required this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final urgency = urgencyOf(note, now);
    final done = note.isCompleted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!note.isChecklist)
                  GestureDetector(
                    onTap: onToggleDone,
                    child: Padding(
                      padding: const EdgeInsets.only(right: Insets.md, top: 2),
                      child: Icon(
                        done
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        size: 22,
                        color: done ? AppColors.income : c.textSecondary,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: AppType.bodyStrong.copyWith(
                          color: done ? c.textSecondary : c.textPrimary,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (note.body != null && note.body!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          note.body!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.caption.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (note.hasReminder && !done)
                  Padding(
                    padding: const EdgeInsets.only(left: Insets.sm),
                    child: Icon(CupertinoIcons.bell_fill,
                        size: 14, color: c.textHint),
                  ),
              ],
            ),
            if (note.isChecklist) ...[
              const SizedBox(height: Insets.sm),
              ...note.items.take(4).map(
                    (item) => InkWell(
                      onTap: () => onToggleItem(item.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              item.isDone
                                  ? CupertinoIcons.checkmark_square_fill
                                  : CupertinoIcons.square,
                              size: 18,
                              color: item.isDone
                                  ? AppColors.income
                                  : c.textSecondary,
                            ),
                            const SizedBox(width: Insets.sm),
                            Expanded(
                              child: Text(
                                item.text,
                                style: AppType.caption.copyWith(
                                  color: item.isDone
                                      ? c.textSecondary
                                      : c.textPrimary,
                                  decoration: item.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              if (note.items.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    s.notes_progress(note.doneCount, note.items.length),
                    style: AppType.caption.copyWith(color: c.textHint),
                  ),
                ),
            ],
            if (note.hasDeadline) ...[
              const SizedBox(height: Insets.sm),
              Row(
                children: [
                  Icon(CupertinoIcons.calendar,
                      size: 13,
                      color: done ? c.textHint : urgencyColor(urgency)),
                  const SizedBox(width: Insets.xs),
                  Text(
                    deadlineLabel(note, now, s, isId),
                    style: AppType.caption.copyWith(
                      color: done ? c.textHint : urgencyColor(urgency),
                      fontWeight: urgency == NoteUrgency.overdue
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
