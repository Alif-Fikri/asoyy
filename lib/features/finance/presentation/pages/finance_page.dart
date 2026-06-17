import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../services/finance_csv_service.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../widgets/finance_chart.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExportDialog(transactions: state.all),
    );
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
          body: _buildBody(context, state),
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
  late int? _year;
  late int? _month;

  @override
  void initState() {
    super.initState();
    _year = widget.selectedYear;
    _month = widget.selectedMonth;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final isId = context.currentLocale.languageCode == 'id';
    final locale = isId ? 'id_ID' : 'en_US';
    final now = DateTime.now();
    final years = [now.year, now.year - 1, now.year - 2];

    final items = <Widget>[
      _ListRow(
        label: s.fin_period_all,
        isSelected: _year == null,
        color: AppColors.primary,
        onTap: () {
          setState(() {
            _year = null;
            _month = null;
          });
          widget.onChanged(null, null);
          widget.onClose();
        },
      ),
      _SectionHeader(label: isId ? 'TAHUN' : 'YEAR'),
      ...years.map(
        (y) => _ListRow(
          label: '$y',
          isSelected: _year == y,
          color: AppColors.primary,
          onTap: () {
            setState(() {
              _year = y;
              _month = null;
            });
            widget.onChanged(y, null);
          },
        ),
      ),
      if (_year != null) ...[
        _SectionHeader(label: isId ? 'BULAN' : 'MONTH'),
        ...List.generate(12, (i) {
          final month = i + 1;
          final label =
              DateFormat('MMMM', locale).format(DateTime(2000, month));
          return _ListRow(
            label: label,
            isSelected: _month == month,
            color: AppColors.income,
            onTap: () {
              final newMonth = _month == month ? null : month;
              setState(() => _month = newMonth);
              widget.onChanged(_year, newMonth);
              if (newMonth != null) widget.onClose();
            },
          );
        }),
      ],
    ];

    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
            child: Row(
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
          ),
          Divider(height: 1, color: c.divider),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: ListView(shrinkWrap: true, children: items),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Text(
        label,
        style: TextStyle(
          color: context.colors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _ListRow({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : c.border,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : c.textPrimary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(CupertinoIcons.check_mark, size: 16, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExportDialog extends StatefulWidget {
  final List<TransactionEntity> transactions;
  const _ExportDialog({required this.transactions});

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  TransactionType? _type;
  late DateTime _from;
  late DateTime _to;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
  }

  List<TransactionEntity> get _filtered {
    final from = DateTime(_from.year, _from.month, _from.day);
    final to = DateTime(_to.year, _to.month, _to.day, 23, 59, 59);
    return widget.transactions.where((t) {
      if (_type != null && t.type != _type) return false;
      return !t.date.isBefore(from) && !t.date.isAfter(to);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_from.isAfter(_to)) _to = picked;
      } else {
        _to = picked;
        if (_to.isBefore(_from)) _from = picked;
      }
    });
  }

  Future<void> _export() async {
    final txs = _filtered;
    final s = context.strings;
    final isId = context.currentLocale.languageCode == 'id';
    final screenSize = MediaQuery.of(context).size;
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.fin_export_empty)),
      );
      return;
    }
    setState(() => _isExporting = true);
    try {
      final file = await FinanceCsvService().exportToFile(txs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isId ? 'CSV disimpan' : 'CSV saved'),
          action: SnackBarAction(
            label: isId ? 'Bagikan' : 'Share',
            onPressed: () => Share.shareXFiles(
              [XFile(file.path, mimeType: 'text/csv')],
              sharePositionOrigin: Rect.fromLTWH(
                0, screenSize.height - 100, screenSize.width, 100),
            ),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isId ? 'Gagal menyimpan CSV' : 'Failed to save CSV'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final isId = context.currentLocale.languageCode == 'id';
    final locale = isId ? 'id_ID' : 'en_US';
    final count = _filtered.length;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
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
                  color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(s.fin_export,
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Text(isId ? 'Jenis Transaksi' : 'Transaction Type',
              style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              _ExportChip(
                label: s.fin_all,
                isSelected: _type == null,
                color: AppColors.primary,
                onTap: () => setState(() => _type = null),
              ),
              const SizedBox(width: 8),
              _ExportChip(
                label: s.fin_income,
                isSelected: _type == TransactionType.income,
                color: AppColors.income,
                onTap: () => setState(() => _type = TransactionType.income),
              ),
              const SizedBox(width: 8),
              _ExportChip(
                label: s.fin_expense,
                isSelected: _type == TransactionType.expense,
                color: AppColors.expense,
                onTap: () => setState(() => _type = TransactionType.expense),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(isId ? 'Rentang Tanggal' : 'Date Range',
              style: TextStyle(color: c.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: s.fin_export_from,
                  date: _from,
                  locale: locale,
                  onTap: () => _pickDate(true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(CupertinoIcons.arrow_right,
                    size: 14, color: c.textSecondary),
              ),
              Expanded(
                child: _DateButton(
                  label: s.fin_export_to,
                  date: _to,
                  locale: locale,
                  onTap: () => _pickDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$count ${isId ? 'transaksi dipilih' : 'transaction${count == 1 ? '' : 's'} selected'}',
            style: TextStyle(color: c.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: _isExporting
                ? (isId ? 'Mengekspor...' : 'Exporting...')
                : s.fin_export,
            onTap: _isExporting ? () {} : _export,
            width: double.infinity,
            color: AppColors.income,
            icon: CupertinoIcons.arrow_down_to_line,
          ),
        ],
      ),
    );
  }
}

class _ExportChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ExportChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : c.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final String locale;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final formatted = DateFormat('d MMM yyyy', locale).format(date);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.cardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: c.textSecondary, fontSize: 11)),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(formatted,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                Icon(CupertinoIcons.calendar,
                    size: 14, color: c.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
