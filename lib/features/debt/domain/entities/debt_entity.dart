enum DebtDirection { iOwe, theyOweMe }

class DebtEntity {
  final String id;
  final String personName;
  final double amount;
  final DebtDirection direction;
  final String? note;
  final DateTime date;
  final DateTime? dueDate;
  final bool isSettled;
  final String? sourceBillId;
  final String? sourceParticipantId;

  const DebtEntity({
    required this.id,
    required this.personName,
    required this.amount,
    required this.direction,
    this.note,
    required this.date,
    this.dueDate,
    this.isSettled = false,
    this.sourceBillId,
    this.sourceParticipantId,
  });

  bool get isFromBill => sourceBillId != null && sourceParticipantId != null;

  DateTime get reminderAnchor => dueDate ?? date;

  DebtEntity copyWith({
    String? personName,
    double? amount,
    DebtDirection? direction,
    String? note,
    DateTime? date,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isSettled,
  }) => DebtEntity(
        id: id,
        personName: personName ?? this.personName,
        amount: amount ?? this.amount,
        direction: direction ?? this.direction,
        note: note ?? this.note,
        date: date ?? this.date,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        isSettled: isSettled ?? this.isSettled,
        sourceBillId: sourceBillId,
        sourceParticipantId: sourceParticipantId,
      );
}
