class Credential {
  final String id;
  final String serviceName;
  final String username;
  final String encryptedPassword;
  final String encryptedNotes;
  final DateTime createdAt;

  Credential({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.encryptedPassword,
    this.encryptedNotes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'username': username,
        'encryptedPassword': encryptedPassword,
        'encryptedNotes': encryptedNotes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Credential.fromJson(Map<String, dynamic> json) => Credential(
        id: json['id'],
        serviceName: json['serviceName'],
        username: json['username'],
        encryptedPassword: json['encryptedPassword'],
        encryptedNotes: json['encryptedNotes'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
      );
}
