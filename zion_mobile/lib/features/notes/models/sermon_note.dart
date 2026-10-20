class SermonNote {
  final String id;
  final String title;
  final String preacher;
  final String scripture;
  final String content;
  final DateTime date;

  SermonNote({
    required this.id,
    required this.title,
    required this.preacher,
    required this.scripture,
    required this.content,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'preacher': preacher,
      'scripture': scripture,
      'content': content,
      'date': date.toIso8601String(),
    };
  }

  factory SermonNote.fromJson(Map<String, dynamic> json) {
    return SermonNote(
      id: json['id'] as String,
      title: json['title'] as String,
      preacher: json['preacher'] as String,
      scripture: json['scripture'] as String,
      content: json['content'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
