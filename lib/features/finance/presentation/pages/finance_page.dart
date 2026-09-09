import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../widgets/finance_chart.dart';
import '../widgets/finance_export_dialog.dart';
import '../widgets/finance_summary.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_form_dialog.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFormDialog(
        onSave: (tx) =>
            context.read<FinanceBloc>().add(AddTransactionRequested(tx)),
      ),
    );
  }

  void _showExportDialog(BuildContext context, FinanceLoaded state) {
    showFinanceExportSheet(context, state.all);
  }

  void _showPeriodPicker(BuildContext context, FinanceLoaded state) {
    showDialog(
      context: context,
      builder: (_) => _PeriodPickerDialog(
        selectedYear: state.filterYear,
        selectedMonth: state.filterMonth,
        onChanged: (year, month) {
          context
              .read<FinanceBloc>()
              .add(FilterPeriodChanged(year: year, month: month));
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: c.background,
          appBar: NexusAppBar(
            title: context.strings.fin_title,
            showLanguageToggle: true,
            extraActions: [
              if (state is FinanceLoaded)
                IconButton(
                  icon: const Icon(CupertinoIcons.arrow_down_to_line),
                  onPressed: () => _showExportDialog(context, state),
                  tooltip: context.strings.fin_export,
                ),
              IconButton(
                icon: const Icon(CupertinoIcons.plus_circle),
                onPressed: () => _showAddTransaction(context),
                tooltip: context.strings.fin_add,
              ),
            ],
          ),
          body: SafeArea(child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FinanceState state) {
    final s = context.strings;
    final isId = Localizations.localeOf(context).languageCode == 'id';

    if (state is FinanceLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is FinanceError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: AppColors.alarmColor),
        ),
      );
    }
    if (state is FinanceLoaded) {
      final txs = state.filtered;
      return ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          8,
          0,
          MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [

          IosSection(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              FinanceSummary(
                balance: state.balance,
                income: state.totalIncome,
                expense: state.totalExpense,
              ),
            ],
          ),

          IosSection(
            header: isId ? 'Grafik 6 Bulan' : '6 Month Chart',
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [FinanceChart(transactions: state.all)],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _TypeFilterRow(
              state: state,
              onPeriodTap: () => _showPeriodPicker(context, state),
            ),
          ),

          if (txs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: EmptyStateWidget(
                icon: CupertinoIcons.doc_text,
                title: state.filter == null
                    ? s.fin_empty_title
                    : s.fin_empty_data,
                subtitle: s.fin_empty_subtitle,
              ),
            )
          else
            IosSection(
              header: isId ? 'Transaksi' : 'Transactions',
              children: txs
                  .map(
                    (tx) => TransactionCard(
                      transaction: tx,
                      onDelete: () => context
                          .read<FinanceBloc>()
                          .add(DeleteTransactionRequested(tx.id)),
                    ),
                  )
                  .toList(),
            ),
        ],
      );
    }
    return const SizedBox();
  }
}

class _TypeFilterRow extends StatelessWidget {
  final FinanceLoaded state;
  final VoidCallback onPeriodTap;
  const _TypeFilterRow({required this.state, required this.onPeriodTap});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FilterChip(
              label: s.fin_all,
              isSelected: state.filter == null,
              onTap: () =>
                  context.read<FinanceBloc>().add(FilterChanged(null)),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: s.fin_income,
              color: AppColors.income,
              isSelected: state.filter == TransactionType.income,
              onTap: () => context
                  .read<FinanceBloc>()
                  .add(FilterChanged(TransactionType.income)),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: s.fin_expense,
              color: AppColors.expense,
              isSelected: state.filter == TransactionType.expense,
              onTap: () => context
                  .read<FinanceBloc>()
                  .add(FilterChanged(TransactionType.expense)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PeriodChip(state: state, onTap: onPeriodTap),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.15) : c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? chipColor : c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? chipColor : c.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final FinanceLoaded state;
  final VoidCallback onTap;

  const _PeriodChip({required this.state, required this.onTap});

  String _label(BuildContext context) {
    final s = context.strings;
    final isId = context.currentLocale.languageCode == 'id';
    final locale = isId ? 'id_ID' : 'en_US';
    if (state.filterYear == null) return s.fin_period_all;
    if (state.filterMonth == null) return '${state.filterYear}';
    final monthName = DateFormat(
      'MMM',
      locale,
    ).format(DateTime(state.filterYear!, state.filterMonth!));
    return '$monthName ${state.filterYear}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isFiltered = state.filterYear != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isFiltered
              ? AppColors.primary.withValues(alpha: 0.12)
              : c.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFiltered ? AppColors.primary : c.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.calendar,
              size: 12,
              color: isFiltered ? AppColors.primary : c.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              _label(context),
              style: TextStyle(
                color: isFiltered ? AppColors.primary : c.textSecondary,
                fontSize: 12,
                fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: isFiltered ? AppColors.primary : c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodPickerDialog extends StatefulWidget {
  final int? selectedYear;
  final int? selectedMonth;
  final void Function(int? year, int? month) onChanged;
  final VoidCallback onClose;

  const _PeriodPickerDialog({
    required this.selectedYear,
    required this.selectedMonth,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<_PeriodPickerDialog> createState() => _PeriodPickerDialogState();
}

class _PeriodPickerDialogState extends State<_PeriodPickerDialog> {
  late int _viewYear;

  @override
  void initState() {
    super.initState();
    _viewYear = widget.selectedYear ?? DateTime.now().year;
  }

  void _pick(int? year, int? month) {
    widget.onChanged(year, month);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final isId = context.currentLocale.languageCode == 'id';
    final locale = isId ? 'id_ID' : 'en_US';
    final isAllTime = widget.selectedYear == null;
    final isFullYear =
        widget.selectedYear == _viewYear && widget.selectedMonth == null;

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  s.fin_period,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(CupertinoIcons.xmark, size: 18, color: c.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _viewYear--),
                  icon: Icon(CupertinoIcons.chevron_left,
                      color: c.textSecondary, size: 18),
                ),
                GestureDetector(
                  onTap: () => _pick(_viewYear, null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFullYear
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFullYear ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      '$_viewYear',
                      style: TextStyle(
                        color: isFullYear ? AppColors.primary : c.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _viewYear++),
                  icon: Icon(CupertinoIcons.chevron_right,
                      color: c.textSecondary, size: 18),
                ),
              ],
            ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: List.generate(12, (i) {
                final month = i + 1;
                final label =
                    DateFormat('MMM', locale).format(DateTime(2000, month));
                final isSelected = widget.selectedYear == _viewYear &&
                    widget.selectedMonth == month;
                return _MonthTile(
                  label: label,
                  isSelected: isSelected,
                  onTap: () => _pick(_viewYear, month),
                );
              }),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: c.divider),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _pick(null, null),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.infinite,
                      size: 16,
                      color: isAllTime ? AppColors.primary : c.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      s.fin_period_all,
                      style: TextStyle(
                        color: isAllTime ? AppColors.primary : c.textPrimary,
                        fontSize: 14,
                        fontWeight:
                            isAllTime ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                    if (isAllTime) ...[
                      const Spacer(),
                      Icon(CupertinoIcons.check_mark,
                          size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MonthTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : c.cardLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : c.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : c.textPrimary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
