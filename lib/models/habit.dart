class Habit {
  final String id;
  final String name;
  final int iconCode;
  final bool isCompleted;
  final int streak;
  final DateTime createdAt;
  final bool isArchived;
  final DateTime? archivedAt;
  final List<String> completedDates; // ISO date strings: '2026-03-01'

  Habit({
    required this.id,
    required this.name,
    required this.iconCode,
    this.isCompleted = false,
    this.streak = 0,
    DateTime? createdAt,
    this.isArchived = false,
    this.archivedAt,
    this.completedDates = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCode': iconCode,
        'isCompleted': isCompleted,
        'streak': streak,
        'createdAt': createdAt.toIso8601String(),
        'isArchived': isArchived,
        if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
        'completedDates': completedDates,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        iconCode: json['iconCode'],
        isCompleted: json['isCompleted'] ?? false,
        streak: json['streak'] ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        isArchived: json['isArchived'] ?? false,
        archivedAt: json['archivedAt'] != null
            ? DateTime.parse(json['archivedAt'])
            : null,
        completedDates: json['completedDates'] != null
            ? List<String>.from(json['completedDates'])
            : [],
      );
}
