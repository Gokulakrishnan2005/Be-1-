class WishlistItem {
  final String id;
  final String title;
  final double price;
  final bool isBought;
  final DateTime createdAt;

  WishlistItem({
    required this.id,
    required this.title,
    required this.price,
    this.isBought = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'isBought': isBought,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'],
        title: json['title'],
        price: json['price'],
        isBought: json['isBought'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}
