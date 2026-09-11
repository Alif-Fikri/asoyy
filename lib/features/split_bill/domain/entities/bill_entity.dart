class ParticipantEntity {
  final String id;
  final String name;
  final double amount;
  final bool isPaid;

  const ParticipantEntity({
    required this.id,
    required this.name,
    required this.amount,
    this.isPaid = false,
  });

  ParticipantEntity copyWith({String? name, double? amount, bool? isPaid}) =>
      ParticipantEntity(
        id: id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        isPaid: isPaid ?? this.isPaid,
      );
}

class BillEntity {
  final String id;
  final String title;
  final double totalAmount;
  final DateTime date;
  final List<ParticipantEntity> participants;
  final bool splitEqually;

  const BillEntity({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.date,
    required this.participants,
    required this.splitEqually,
  });

  double get collectedAmount =>
      participants.where((p) => p.isPaid).fold(0, (s, p) => s + p.amount);

  double get outstandingAmount => totalAmount - collectedAmount;

  bool get isFullySettled => participants.every((p) => p.isPaid);

  BillEntity copyWith({
    String? title,
    double? totalAmount,
    DateTime? date,
    List<ParticipantEntity>? participants,
    bool? splitEqually,
  }) => BillEntity(
        id: id,
        title: title ?? this.title,
        totalAmount: totalAmount ?? this.totalAmount,
        date: date ?? this.date,
        participants: participants ?? this.participants,
        splitEqually: splitEqually ?? this.splitEqually,
      );
}
