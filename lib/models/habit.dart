class Habit {
  final String id;
  final String name;
  final int iconCode;
  final bool isCompleted;
  final int streak;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.iconCode,
    this.isCompleted = false,
    this.streak = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCode': iconCode,
        'isCompleted': isCompleted,
        'streak': streak,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        iconCode: json['iconCode'],
        isCompleted: json['isCompleted'] ?? false,
        streak: json['streak'] ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(), // Fallback for old data
      );
}
