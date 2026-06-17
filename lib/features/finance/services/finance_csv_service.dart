import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../domain/entities/transaction_entity.dart';

Future<Directory> _financeDir() async {
  if (Platform.isAndroid) {
    final ext = await getExternalStorageDirectory();
    if (ext != null) return ext;
  }
  return getApplicationDocumentsDirectory();
}

class FinanceCsvService {
  static const _headers = ['date', 'type', 'category', 'title', 'amount', 'notes'];

  String _escape(String? value) {
    if (value == null || value.isEmpty) return '""';
    return '"${value.replaceAll('"', '""')}"';
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String exportToCsvString(List<TransactionEntity> transactions) {
    final buffer = StringBuffer();
    buffer.writeln(_headers.join(','));
    for (final t in transactions) {
      buffer.writeln([
        _escape(_formatDate(t.date)),
        _escape(t.isIncome ? 'income' : 'expense'),
        _escape(t.category),
        _escape(t.title),
        t.amount.toStringAsFixed(2),
        _escape(t.notes),
      ].join(','));
    }
    return buffer.toString();
  }

  Future<File> exportToFile(List<TransactionEntity> transactions) async {
    final dir = await _financeDir();
    final file = File('${dir.path}/vela_finance.csv');
    await file.writeAsString(exportToCsvString(transactions), encoding: utf8);
    return file;
  }
}
