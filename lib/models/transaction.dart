enum TransactionType { income, expense, savings }

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? linkedWishlistId;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.linkedWishlistId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.index,
        'linkedWishlistId': linkedWishlistId,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'],
        title: json['title'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        type: TransactionType.values[json['type']],
        linkedWishlistId: json['linkedWishlistId'],
      );
}
