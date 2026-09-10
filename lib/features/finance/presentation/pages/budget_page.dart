import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/thousand_separator_formatter.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../data/budget_repository.dart';
import '../../data/finance_category_repository.dart';
import '../../domain/entities/transaction_entity.dart';

class BudgetPage extends StatefulWidget {
  final Map<String, double> spentByCategory;

  const BudgetPage({super.key, required this.spentByCategory});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _budgetRepo = BudgetRepository();
  final _catRepo = FinanceCategoryRepository();

  List<String> get _categories {
    final defaults = _catRepo.visibleDefaults(
      TransactionType.expense,
      FinanceCategories.expense,
    );
    final custom = _catRepo.getCustom(TransactionType.expense);
    return [...defaults, ...custom];
  }

  Future<void> _editLimit(String category, double? currentLimit) async {
    final s = context.strings;
    final controller = TextEditingController(
      text: currentLimit != null
          ? NumberFormat.decimalPattern('id_ID').format(currentLimit.round())
          : '',
    );

    final result = await showDialog<_LimitDialogResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandSeparatorFormatter()],
          decoration: InputDecoration(
            labelText: s.fin_budget_limit_label,
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          if (currentLimit != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.alarmColor),
              onPressed: () => Navigator.pop(ctx, _LimitDialogResult.clear),
              child: Text(s.fin_budget_clear_action),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _LimitDialogResult.cancel),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              ctx,
              _LimitDialogResult.save(controller.text),
            ),
            child: Text(s.save),
          ),
        ],
      ),
    );

    if (result == null || result.action == _LimitAction.cancel || !mounted) {
      return;
    }

    if (result.action == _LimitAction.clear) {
      await _budgetRepo.setLimit(category, null);
      if (!mounted) return;
      setState(() {});
      AppToast.show(context, s.fin_budget_cleared);
      return;
    }

    final value = double.tryParse(result.rawAmount!.replaceAll('.', ''));
    if (value == null || value <= 0) {
      AppToast.show(context, s.fin_budget_invalid);
      return;
    }
    await _budgetRepo.setLimit(category, value);
    if (!mounted) return;
    setState(() {});
    AppToast.show(context, s.fin_budget_saved);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final categories = _categories;
    final limits = _budgetRepo.getAll();
    final fmt = NumberFormat.decimalPattern('id_ID');

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.fin_budget_title),
      body: SafeArea(
        child: categories.isEmpty
            ? EmptyStateWidget(
                icon: CupertinoIcons.chart_pie,
                title: s.fin_budget_empty,
                subtitle: s.fin_budget_empty,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(0, Insets.sm, 0, Insets.xl),
                children: [
                  IosSection(
                    children: categories.map((cat) {
                      final limit = limits[cat];
                      final spent = widget.spentByCategory[cat] ?? 0;
                      final ratio = limit != null && limit > 0
                          ? (spent / limit).clamp(0.0, 1.0)
                          : 0.0;
                      final barColor = ratio >= 1.0
                          ? AppColors.expense
                          : ratio >= 0.8
                              ? AppColors.calendarColor
                              : AppColors.income;

                      return InkWell(
                        onTap: () => _editLimit(cat, limit),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Insets.lg,
                            vertical: Insets.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      cat,
                                      style: AppType.bodyStrong.copyWith(
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    limit != null
                                        ? 'Rp ${fmt.format(spent.round())} / Rp ${fmt.format(limit.round())}'
                                        : s.fin_budget_no_limit,
                                    style: AppType.caption.copyWith(
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Insets.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(Radii.sm),
                                child: LinearProgressIndicator(
                                  value: limit != null ? ratio : 0,
                                  minHeight: 6,
                                  backgroundColor: c.cardLight,
                                  color: barColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
      ),
    );
  }
}

enum _LimitAction { save, clear, cancel }

class _LimitDialogResult {
  final _LimitAction action;
  final String? rawAmount;

  const _LimitDialogResult._(this.action, this.rawAmount);

  static const clear = _LimitDialogResult._(_LimitAction.clear, null);
  static const cancel = _LimitDialogResult._(_LimitAction.cancel, null);
  factory _LimitDialogResult.save(String rawAmount) =>
      _LimitDialogResult._(_LimitAction.save, rawAmount);
}
