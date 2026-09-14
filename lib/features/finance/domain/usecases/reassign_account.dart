import '../repositories/finance_repository.dart';

class ReassignAccountParams {
  final String fromId;
  final String toId;
  const ReassignAccountParams({required this.fromId, required this.toId});
}

class ReassignAccount {
  final FinanceRepository repository;
  ReassignAccount(this.repository);

  Future<int> call(ReassignAccountParams params) =>
      repository.reassignAccount(params.fromId, params.toId);
}
