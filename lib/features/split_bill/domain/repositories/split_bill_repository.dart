import '../entities/bill_entity.dart';

abstract class SplitBillRepository {
  Future<List<BillEntity>> getBills();
  Future<void> addBill(BillEntity bill);
  Future<void> updateBill(BillEntity bill);
  Future<void> deleteBill(String id);
}
