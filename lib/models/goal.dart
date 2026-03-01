enum GoalType { weekly, monthly, yearly }

enum GoalStatus { active, success, failed }

class Goal {
  final String id;
  final String title;
  final double targetValue;
  final double currentValue;
  final String unit;
  final GoalType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final GoalStatus status;

  Goal({
    required this.id,
    required this.title,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    required this.type,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.status = GoalStatus.active,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt =
            expiresAt ?? _calculateExpiresAt(type, createdAt ?? DateTime.now());

  static DateTime _calculateExpiresAt(GoalType type, DateTime start) {
    if (type == GoalType.weekly) {
      // Find following Saturday 11:59:59 PM
      int daysUntilSaturday = DateTime.saturday - start.weekday;
      if (daysUntilSaturday < 0) daysUntilSaturday += 7;
      final targetDate = start.add(Duration(days: daysUntilSaturday));
      return DateTime(
          targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);
    } else if (type == GoalType.monthly) {
      // Last calendar day of month
      final nextMonth = start.month == 12 ? 1 : start.month + 1;
      final year = start.month == 12 ? start.year + 1 : start.year;
      final lastDay =
          DateTime(year, nextMonth, 1).subtract(const Duration(days: 1));
      return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
    } else {
      // Yearly: Dec 31st
      return DateTime(start.year, 12, 31, 23, 59, 59);
    }
  }

  Goal copyWith({
    String? newTitle,
    double? newTargetValue,
    double? newCurrentValue,
    String? newUnit,
    GoalStatus? newStatus,
  }) {
    return Goal(
      id: id,
      title: newTitle ?? title,
      targetValue: newTargetValue ?? targetValue,
      currentValue: newCurrentValue ?? currentValue,
      unit: newUnit ?? unit,
      type: type,
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: newStatus ?? status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'unit': unit,
        'type': type.index,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'status': status.index,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        title: json['title'],
        targetValue: json['targetValue'],
        currentValue: json['currentValue'] ?? 0,
        unit: json['unit'],
        type: GoalType.values[json['type']],
        createdAt: DateTime.parse(json['createdAt']),
        expiresAt: DateTime.parse(json['expiresAt']),
        status: GoalStatus.values[json['status'] ?? 0],
      );
}
