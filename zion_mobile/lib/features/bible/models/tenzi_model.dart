class TenziStanza {
  final int verseNumber;
  final String text;

  const TenziStanza({
    required this.verseNumber,
    required this.text,
  });

  factory TenziStanza.fromJson(Map<String, dynamic> json) {
    return TenziStanza(
      verseNumber: json['verse_number'] is int
          ? json['verse_number'] as int
          : int.tryParse(json['verse_number'].toString()) ?? 1,
      text: json['text']?.toString() ?? '',
    );
  }
}

class TenziHymn {
  final int number;
  final String title;
  final String category;
  final String key;
  final String timeSignature;
  final List<TenziStanza> stanzas;
  final String? chorus;

  const TenziHymn({
    required this.number,
    required this.title,
    required this.category,
    required this.key,
    required this.timeSignature,
    required this.stanzas,
    this.chorus,
  });

  factory TenziHymn.fromJson(Map<String, dynamic> json) {
    final rawStanzas = json['stanzas'] as List<dynamic>? ?? [];
    return TenziHymn(
      number: json['number'] is int
          ? json['number'] as int
          : int.tryParse(json['number'].toString()) ?? 1,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      timeSignature: json['time_signature']?.toString() ?? '',
      stanzas: rawStanzas
          .map((s) => TenziStanza.fromJson(s as Map<String, dynamic>))
          .toList(),
      chorus: json['chorus']?.toString(),
    );
  }
}
