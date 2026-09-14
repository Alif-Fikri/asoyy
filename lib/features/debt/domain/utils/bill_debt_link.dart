import '../../../finance/domain/entities/transaction_entity.dart';
import '../../../split_bill/domain/entities/bill_entity.dart';
import '../entities/debt_entity.dart';

const String settlementCategory = 'Lainnya';

bool _linksTo(DebtEntity debt, String billId, String participantId) =>
    debt.sourceBillId == billId && debt.sourceParticipantId == participantId;

DebtEntity? debtForParticipant(
  List<DebtEntity> debts,
  String billId,
  String participantId,
) {
  for (final debt in debts) {
    if (_linksTo(debt, billId, participantId)) return debt;
  }
  return null;
}

List<ParticipantEntity> participantsWithoutDebt(
  BillEntity bill,
  List<DebtEntity> debts,
) =>
    bill.participants
        .where((p) => p.amount > 0)
        .where((p) => !p.isPaid)
        .where((p) => debtForParticipant(debts, bill.id, p.id) == null)
        .toList(growable: false);

List<DebtEntity> debtsFromBill(
  BillEntity bill,
  List<DebtEntity> existing, {
  required String Function(ParticipantEntity) idFor,
}) =>
    participantsWithoutDebt(bill, existing)
        .map((p) => DebtEntity(
              id: idFor(p),
              personName: p.name,
              amount: p.amount,
              direction: DebtDirection.theyOweMe,
              note: bill.title,
              date: bill.date,
              sourceBillId: bill.id,
              sourceParticipantId: p.id,
            ))
        .toList(growable: false);

TransactionEntity transactionForSettledDebt(
  DebtEntity debt, {
  required String id,
  required String settlementTitle,
  String? accountId,
  DateTime? on,
}) =>
    TransactionEntity(
      id: id,
      title: settlementTitle,
      amount: debt.amount,
      type: debt.direction == DebtDirection.theyOweMe
          ? TransactionType.income
          : TransactionType.expense,
      category: settlementCategory,
      date: on ?? DateTime.now(),
      notes: debt.note,
      accountId: accountId,
    );
