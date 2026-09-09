import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/utils/quick_add_parser.dart';

Future<void> showQuickAddSheet(
  BuildContext context,
  void Function(TransactionEntity) onSave,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => QuickAddDialog(onSave: onSave),
  );
}

class QuickAddDialog extends StatefulWidget {
  final void Function(TransactionEntity) onSave;

  const QuickAddDialog({super.key, required this.onSave});

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  final _controller = TextEditingController();
  QuickAddResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _result = parseQuickAddText(value));
  }

  void _submit() {
    final result = _result;
    if (result == null) return;
    widget.onSave(TransactionEntity(
      id: const Uuid().v4(),
      title: result.title,
      amount: result.amount,
      type: result.type,
      category: result.category,
      date: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final result = _result;
    final fmt = NumberFormat.decimalPattern('id_ID');

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            s.fin_quick_add,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.fin_quick_add_hint,
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            style: TextStyle(color: c.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: s.fin_quick_add_placeholder,
              hintStyle: TextStyle(color: c.textHint, fontSize: 14),
              prefixIcon: Icon(CupertinoIcons.sparkles, color: AppColors.primary),
              filled: true,
              fillColor: c.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (result.type == TransactionType.income
                        ? AppColors.income
                        : AppColors.expense)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (result.type == TransactionType.income
                          ? AppColors.income
                          : AppColors.expense)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result.title,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'Rp ${fmt.format(result.amount)}',
                        style: TextStyle(
                          color: result.type == TransactionType.income
                              ? AppColors.income
                              : AppColors.expense,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(CupertinoIcons.tag, size: 14, color: c.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        result.category,
                        style: TextStyle(color: c.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        result.type == TransactionType.income
                            ? CupertinoIcons.arrow_down
                            : CupertinoIcons.arrow_up,
                        size: 14,
                        color: c.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        result.type == TransactionType.income
                            ? s.fin_income
                            : s.fin_expense,
                        style: TextStyle(color: c.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else if (_controller.text.isNotEmpty)
            Text(
              s.fin_quick_add_unparsed,
              style: TextStyle(color: c.textHint, fontSize: 13),
            ),
          const SizedBox(height: 20),
          AppButton(
            label: s.fin_save,
            onTap: result == null ? null : _submit,
            width: double.infinity,
            color: AppColors.primary,
            icon: CupertinoIcons.check_mark,
          ),
        ],
      ),
    );
  }
}
