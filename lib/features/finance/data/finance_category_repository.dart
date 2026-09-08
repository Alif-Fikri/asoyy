import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/entities/transaction_entity.dart';

class FinanceCategoryRepository {
  static const _incomeKey = 'fin_custom_categories_income';
  static const _expenseKey = 'fin_custom_categories_expense';

  Box get _box => Hive.box(AppConstants.settingsBox);

  String _keyFor(TransactionType type) =>
      type == TransactionType.income ? _incomeKey : _expenseKey;

  List<String> getCustom(TransactionType type) {
    final raw = _box.get(_keyFor(type));
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  Future<void> add(TransactionType type, String name) async {
    final current = getCustom(type);
    if (current.contains(name)) return;
    await _box.put(_keyFor(type), [...current, name]);
  }

  Future<void> remove(TransactionType type, String name) async {
    final current = getCustom(type)..remove(name);
    await _box.put(_keyFor(type), current);
  }
}
