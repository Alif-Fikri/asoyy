import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/bill_model.dart';

abstract class SplitBillLocalDatasource {
  Future<List<BillModel>> getBills();
  Future<void> saveBill(BillModel bill);
  Future<void> deleteBill(String id);
}

class SplitBillLocalDatasourceImpl implements SplitBillLocalDatasource {
  final Box<BillModel> box;
  SplitBillLocalDatasourceImpl(this.box);

  static Future<SplitBillLocalDatasourceImpl> create() async {
    final box = await Hive.openBox<BillModel>(AppConstants.billsBox);
    return SplitBillLocalDatasourceImpl(box);
  }

  @override
  Future<List<BillModel>> getBills() async => box.values.toList();

  @override
  Future<void> saveBill(BillModel bill) => box.put(bill.id, bill);

  @override
  Future<void> deleteBill(String id) => box.delete(id);
}
