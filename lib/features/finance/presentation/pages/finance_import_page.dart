import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../data/account_repository.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/utils/finance_csv_import.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';
import '../widgets/account_picker.dart';

class FinanceImportPage extends StatefulWidget {
  const FinanceImportPage({super.key});

  @override
  State<FinanceImportPage> createState() => _FinanceImportPageState();
}

class _FinanceImportPageState extends State<FinanceImportPage> {
  ParsedCsv? _csv;
  ImportColumnMapping? _mapping;
  AccountEntity? _account;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final accounts = AccountRepository().getAll();
    if (accounts.isNotEmpty) _account = accounts.first;
  }

  Future<void> _pickFile() async {
    final s = context.strings;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;

    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    final csv = parseDelimitedText(content);
    if (csv.rows.isEmpty) {
      if (mounted) AppToast.show(context, s.fin_import_failed);
      return;
    }

    setState(() {
      _csv = csv;
      _mapping = detectColumnMapping(csv.headers);
    });
  }

  Future<void> _import() async {
    final csv = _csv;
    final mapping = _mapping;
    if (csv == null || mapping == null || !mapping.isUsable) return;

    final state = context.read<FinanceBloc>().state;
    if (state is! FinanceLoaded) return;

    final rows = parseImportRows(csv, mapping);
    final toImport = buildImportedTransactions(
      rows: rows,
      accountId: _account?.id,
      defaultExpenseCategory: FinanceCategories.expense.last,
      defaultIncomeCategory: FinanceCategories.income.last,
      existing: state.all,
      generateId: () => const Uuid().v4(),
    );

    final s = context.strings;
    if (toImport.isEmpty) {
      AppToast.show(context, s.fin_import_no_rows);
      return;
    }

    setState(() => _busy = true);
    context.read<FinanceBloc>().add(AddTransactionsBatchRequested(toImport));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    AppToast.show(context, s.fin_import_success(toImport.length));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final csv = _csv;
    final mapping = _mapping;

    final rows = csv != null && mapping != null && mapping.isUsable
        ? parseImportRows(csv, mapping)
        : const <ImportedRow>[];
    final validRows = rows.where((r) => r.isValid).toList();
    final financeState = context.watch<FinanceBloc>().state;
    final existing = financeState is FinanceLoaded ? financeState.all : const <TransactionEntity>[];
    final skipped = validRows.where((r) => isDuplicateTransaction(r, existing)).length;
    final toImportCount = validRows.length - skipped;

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.fin_import),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Insets.lg,
            Insets.md,
            Insets.lg,
            MediaQuery.of(context).padding.bottom + Insets.xxl,
          ),
          children: [
            AppButton(
              label: s.fin_import_pick_file,
              icon: CupertinoIcons.doc_text,
              onTap: _pickFile,
            ),
            if (csv != null) ...[
              const SizedBox(height: Insets.lg),
              if (mapping == null || !mapping.isUsable) ...[
                Text(
                  s.fin_import_needs_mapping,
                  style: AppType.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: Insets.md),
                _ColumnMappingEditor(
                  headers: csv.headers,
                  mapping: mapping ?? const ImportColumnMapping(),
                  onChanged: (m) => setState(() => _mapping = m),
                  s: s,
                ),
              ] else ...[
                Text(
                  s.fin_import_preview_title.toUpperCase(),
                  style: AppType.label.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: Insets.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Insets.lg),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    s.fin_import_preview_summary(toImportCount, skipped),
                    style: AppType.body.copyWith(color: c.textPrimary),
                  ),
                ),
                const SizedBox(height: Insets.lg),
                AccountField(
                  label: s.fin_import_wallet_label,
                  account: _account,
                  onTap: () async {
                    final accounts = AccountRepository().getAll();
                    final picked = await showAccountPicker(context, accounts, _account?.id);
                    if (picked != null) setState(() => _account = picked);
                  },
                ),
                const SizedBox(height: Insets.xl),
                AppButton(
                  label: s.fin_import_confirm,
                  isLoading: _busy,
                  onTap: toImportCount > 0 ? _import : null,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ColumnMappingEditor extends StatelessWidget {
  final List<String> headers;
  final ImportColumnMapping mapping;
  final ValueChanged<ImportColumnMapping> onChanged;
  final AppStrings s;

  const _ColumnMappingEditor({
    required this.headers,
    required this.mapping,
    required this.onChanged,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ColumnDropdown(
          label: s.fin_import_map_date,
          headers: headers,
          value: mapping.dateColumn,
          none: s.fin_import_column_none,
          onChanged: (v) => onChanged(mapping.copyWith(dateColumn: v)),
        ),
        const SizedBox(height: Insets.md),
        _ColumnDropdown(
          label: s.fin_import_map_amount,
          headers: headers,
          value: mapping.amountColumn,
          none: s.fin_import_column_none,
          onChanged: (v) => onChanged(mapping.copyWith(amountColumn: v)),
        ),
        const SizedBox(height: Insets.md),
        _ColumnDropdown(
          label: s.fin_import_map_debit,
          headers: headers,
          value: mapping.debitColumn,
          none: s.fin_import_column_none,
          onChanged: (v) => onChanged(mapping.copyWith(debitColumn: v)),
        ),
        const SizedBox(height: Insets.md),
        _ColumnDropdown(
          label: s.fin_import_map_credit,
          headers: headers,
          value: mapping.creditColumn,
          none: s.fin_import_column_none,
          onChanged: (v) => onChanged(mapping.copyWith(creditColumn: v)),
        ),
        const SizedBox(height: Insets.md),
        _ColumnDropdown(
          label: s.fin_import_map_description,
          headers: headers,
          value: mapping.descriptionColumn,
          none: s.fin_import_column_none,
          onChanged: (v) => onChanged(mapping.copyWith(descriptionColumn: v)),
        ),
      ],
    );
  }
}

class _ColumnDropdown extends StatelessWidget {
  final String label;
  final List<String> headers;
  final int? value;
  final String none;
  final ValueChanged<int?> onChanged;

  const _ColumnDropdown({
    required this.label,
    required this.headers,
    required this.value,
    required this.none,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppType.body.copyWith(color: c.textPrimary)),
        ),
        DropdownButton<int?>(
          value: value,
          hint: Text(none),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(none)),
            for (var i = 0; i < headers.length; i++)
              DropdownMenuItem<int?>(value: i, child: Text(headers[i])),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
