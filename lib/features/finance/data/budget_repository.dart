import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';

class BudgetRepository {
  static const _key = 'fin_category_budgets';

  Box get _box => Hive.box(AppConstants.settingsBox);

  Map<String, double> getAll() {
    final raw = _box.get(_key);
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }
    return {};
  }

  double? getLimit(String category) => getAll()[category];

  Future<void> setLimit(String category, double? limit) async {
    final current = getAll();
    if (limit == null || limit <= 0) {
      current.remove(category);
    } else {
      current[category] = limit;
    }
    await _box.put(_key, current);
  }
}
