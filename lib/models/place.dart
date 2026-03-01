class Place {
  final String id;
  final String name;
  final String country;
  final String bestTimeToVisit;
  final bool isVisited;
  final String notes;
  final DateTime createdAt;

  Place({
    required this.id,
    required this.name,
    required this.country,
    this.bestTimeToVisit = '',
    this.isVisited = false,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Place copyWith({
    String? newName,
    String? newCountry,
    String? newBestTime,
    bool? newIsVisited,
    String? newNotes,
  }) =>
      Place(
        id: id,
        name: newName ?? name,
        country: newCountry ?? country,
        bestTimeToVisit: newBestTime ?? bestTimeToVisit,
        isVisited: newIsVisited ?? isVisited,
        notes: newNotes ?? notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'bestTimeToVisit': bestTimeToVisit,
        'isVisited': isVisited,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'],
        name: json['name'],
        country: json['country'],
        bestTimeToVisit: json['bestTimeToVisit'] ?? '',
        isVisited: json['isVisited'] ?? false,
        notes: json['notes'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
      );
}
