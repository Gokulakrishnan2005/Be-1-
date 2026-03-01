enum TransactionType { income, expense, savings, transfer }

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? linkedWishlistId;
  final String? category;

  TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.linkedWishlistId,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.index,
        'linkedWishlistId': linkedWishlistId,
        'category': category,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'],
        title: json['title'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        type: TransactionType.values[json['type']],
        linkedWishlistId: json['linkedWishlistId'],
        category: json['category'],
      );
}
