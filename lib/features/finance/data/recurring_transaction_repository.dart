import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/entities/recurring_transaction_entity.dart';
import '../domain/entities/transaction_entity.dart';
import '../domain/repositories/finance_repository.dart';

class RecurringTransactionRepository {
  static const _key = 'fin_recurring_transactions';

  Box get _box => Hive.box(AppConstants.settingsBox);

  List<RecurringTransactionEntity> getAll() {
    final raw = _box.get(_key) as String?;
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => RecurringTransactionEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<RecurringTransactionEntity> items) async {
    await _box.put(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<RecurringTransactionEntity> add({
    required String title,
    required double amount,
    required TransactionType type,
    required String category,
    required int dayOfMonth,
    String? notes,
  }) async {
    final entity = RecurringTransactionEntity(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      type: type,
      category: category,
      dayOfMonth: dayOfMonth,
      notes: notes,
    );
    await _saveAll([...getAll(), entity]);
    return entity;
  }

  Future<void> delete(String id) async {
    await _saveAll(getAll().where((e) => e.id != id).toList());
  }

  Future<void> markSkipped(String id, String monthKey) async {
    await _saveAll(getAll()
        .map((e) => e.id == id ? e.copyWith(lastGeneratedMonth: monthKey) : e)
        .toList());
  }

  Future<int> generateDueTransactions(FinanceRepository financeRepository) async {
    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final items = getAll();
    var generated = 0;
    final updated = <RecurringTransactionEntity>[];

    for (final item in items) {
      if (item.lastGeneratedMonth == currentMonthKey ||
          now.day < item.dayOfMonth) {
        updated.add(item);
        continue;
      }
      await financeRepository.addTransaction(TransactionEntity(
        id: const Uuid().v4(),
        title: item.title,
        amount: item.amount,
        type: item.type,
        category: item.category,
        date: DateTime(now.year, now.month, item.dayOfMonth),
        notes: item.notes,
      ));
      generated++;
      updated.add(item.copyWith(lastGeneratedMonth: currentMonthKey));
    }

    if (generated > 0) await _saveAll(updated);
    return generated;
  }
}
