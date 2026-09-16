import '../entities/transaction_entity.dart';

class PendingCapture {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final int postTime;

  const PendingCapture({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.postTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'type': type.name,
        'postTime': postTime,
      };

  factory PendingCapture.fromJson(Map<String, dynamic> json) => PendingCapture(
        id: json['id'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => TransactionType.expense,
        ),
        postTime: (json['postTime'] as num).toInt(),
      );
}
