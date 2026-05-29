import 'package:flutter/cupertino.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../domain/entities/holiday_entity.dart';

class HolidayListItem extends StatelessWidget {
  final HolidayEntity holiday;

  const HolidayListItem({super.key, required this.holiday});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color =
        holiday.isNational ? AppColors.alarmColor : AppColors.calendarColor;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final name = isId ? holiday.nameId : holiday.nameEn;
    final typeLabel = holiday.isNational
        ? (isId ? 'Hari Libur Nasional' : 'National Holiday')
        : (isId ? 'Cuti Bersama' : 'Joint Leave');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              holiday.isNational ? CupertinoIcons.flag : CupertinoIcons.bed_double,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  typeLabel,
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaydayListItem extends StatelessWidget {
  const PaydayListItem({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.money_dollar_circle,
              color: AppColors.income,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isId ? 'Gajian' : 'Payday',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isId ? 'Penanda gajian bulanan' : 'Monthly payday marker',
                  style: const TextStyle(
                    color: AppColors.income,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
