import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/split_bill_repository.dart';
import '../datasources/split_bill_local_datasource.dart';
import '../models/bill_model.dart';

class SplitBillRepositoryImpl implements SplitBillRepository {
  final SplitBillLocalDatasource datasource;
  SplitBillRepositoryImpl(this.datasource);

  @override
  Future<List<BillEntity>> getBills() async {
    final models = await datasource.getBills();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addBill(BillEntity bill) =>
      datasource.saveBill(BillModel.fromEntity(bill));

  @override
  Future<void> updateBill(BillEntity bill) =>
      datasource.saveBill(BillModel.fromEntity(bill));

  @override
  Future<void> deleteBill(String id) => datasource.deleteBill(id);
}
