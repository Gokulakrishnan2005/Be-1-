class Skill {
  final String id;
  final String name;
  final String iconName;
  final int targetHours;
  final String category; // 'GROWTH', 'MAINTENANCE', 'ENTROPY'

  Skill({
    required this.id,
    required this.name,
    required this.iconName,
    required this.targetHours,
    this.category = 'GROWTH',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconName': iconName,
        'targetHours': targetHours,
        'category': category,
      };

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'],
        name: json['name'],
        iconName: json['iconName'],
        targetHours: json['targetHours'],
        category: json['category'] ?? 'GROWTH',
      );
}
