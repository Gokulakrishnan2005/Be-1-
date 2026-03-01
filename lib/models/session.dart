class Session {
  final String id;
  final String skillId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final bool isEdited;

  Session({
    required this.id,
    required this.skillId,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    this.isEdited = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'skillId': skillId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationSeconds': durationSeconds,
        'isEdited': isEdited,
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'],
        skillId: json['skillId'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        durationSeconds: json['durationSeconds'],
        isEdited: json['isEdited'] ?? false,
      );
}
