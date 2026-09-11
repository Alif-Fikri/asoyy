import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/debt_model.dart';

abstract class DebtLocalDatasource {
  Future<List<DebtModel>> getDebts();
  Future<void> saveDebt(DebtModel debt);
  Future<void> deleteDebt(String id);
}

class DebtLocalDatasourceImpl implements DebtLocalDatasource {
  final Box<DebtModel> box;
  DebtLocalDatasourceImpl(this.box);

  static Future<DebtLocalDatasourceImpl> create() async {
    final box = await Hive.openBox<DebtModel>(AppConstants.debtsBox);
    return DebtLocalDatasourceImpl(box);
  }

  @override
  Future<List<DebtModel>> getDebts() async => box.values.toList();

  @override
  Future<void> saveDebt(DebtModel debt) => box.put(debt.id, debt);

  @override
  Future<void> deleteDebt(String id) => box.delete(id);
}
