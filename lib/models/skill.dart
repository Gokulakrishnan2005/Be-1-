class Skill {
  final String id;
  final String name;
  final String iconName;
  final int targetHours;
  final String category; // 'GROWTH', 'MAINTENANCE', 'ENTROPY'
  final int orderIndex;

  Skill({
    required this.id,
    required this.name,
    required this.iconName,
    required this.targetHours,
    this.category = 'GROWTH',
    this.orderIndex = 99,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'targetHours': targetHours,
        'category': category,
        'orderIndex': orderIndex,
      };

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'],
        name: json['name'],
        iconName: json['iconName'],
        targetHours: json['targetHours'],
        category: json['category'] ?? 'GROWTH',
        orderIndex: json['orderIndex'] ?? 99,
      );
}
