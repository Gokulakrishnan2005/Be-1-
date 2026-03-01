class ContentBlock {
  final String type; // 'paragraph', 'heading', 'subheading', 'image'
  String content; // text or local file path for images

  ContentBlock({required this.type, required this.content});

  Map<String, dynamic> toJson() => {'type': type, 'content': content};

  factory ContentBlock.fromJson(Map<String, dynamic> json) =>
      ContentBlock(type: json['type'], content: json['content']);
}

class JournalEntry {
  final String id;
  String title;
  final DateTime date;
  String mood; // 'positive' or 'negative'
  List<ContentBlock> contentBlocks;

  JournalEntry({
    required this.id,
    required this.title,
    DateTime? date,
    this.mood = 'positive',
    List<ContentBlock>? contentBlocks,
  })  : date = date ?? DateTime.now(),
        contentBlocks = contentBlocks ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'mood': mood,
        'contentBlocks': contentBlocks.map((b) => b.toJson()).toList(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'],
        title: json['title'],
        date: DateTime.parse(json['date']),
        mood: json['mood'] ?? 'positive',
        contentBlocks: (json['contentBlocks'] as List)
            .map((b) => ContentBlock.fromJson(b))
            .toList(),
      );
}
