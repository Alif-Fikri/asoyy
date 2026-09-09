import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/utils/csv_share.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../services/finance_csv_service.dart';

Future<void> showFinanceExportSheet(
  BuildContext context,
  List<TransactionEntity> transactions,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FinanceExportDialog(transactions: transactions),
  );
}

class FinanceExportDialog extends StatefulWidget {
  final List<TransactionEntity> transactions;
  const FinanceExportDialog({super.key, required this.transactions});

  @override
  State<FinanceExportDialog> createState() => _FinanceExportDialogState();
}

class _FinanceExportDialogState extends State<FinanceExportDialog> {
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
      await shareCsvSnackBar(context, file);
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
