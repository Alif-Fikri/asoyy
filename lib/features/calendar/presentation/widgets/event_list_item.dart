import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../domain/entities/event_entity.dart';

class EventListItem extends StatelessWidget {
  final EventEntity event;
  final VoidCallback onDelete;

  const EventListItem({super.key, required this.event, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () async {
          final confirmed = await showDeleteConfirm(context);
          if (confirmed) onDelete();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: event.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.description!,
                        style: TextStyle(color: c.textSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.trash,
                  color: AppColors.alarmColor.withValues(alpha: 0.85),
                  size: 18,
                ),
                onPressed: () async {
                  final confirmed = await showDeleteConfirm(context);
                  if (confirmed) onDelete();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
