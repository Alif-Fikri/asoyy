import 'package:flutter/material.dart';
import '../theme/app_color_theme.dart';

class SegmentedTab<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? color;

  const SegmentedTab({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });
}

class SegmentedTabBar<T> extends StatelessWidget {
  final List<SegmentedTab<T>> tabs;
  final T selected;
  final Color color;
  final ValueChanged<T> onChanged;

  const SegmentedTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = tab.value == selected;
          final activeColor = tab.color ?? color;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tab.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (tab.icon != null) ...[
                      Icon(tab.icon, color: isSelected ? activeColor : c.textHint, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        tab.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? activeColor : c.textHint,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
