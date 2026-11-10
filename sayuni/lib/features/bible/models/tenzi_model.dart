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

/// A hymn in either collection. Both collections ship **full offline
/// lyrics** — the app never depends on an external hymn website.
///
/// - **Tenzi za Rohoni** (`collection == 'tenzi'`): the original bundled
///   Swahili hymnal (46 hymns).
/// - **Nyimbo za Kikristo** (`collection == 'nyimbo'`): 32 fresh Swahili
///   translations of classic public-domain hymns written for this project
///   (marked with `lyricsNote`). No lyrics are copied from any website or
///   modern hymnal, and there are no outbound links.
class TenziHymn {
  final int number;
  final String title;
  final String category;
  final String key;
  final String timeSignature;
  final List<TenziStanza> stanzas;
  final String? chorus;

  /// 'tenzi' or 'nyimbo'.
  final String collection;

  const TenziHymn({
    required this.number,
    required this.title,
    required this.category,
    required this.key,
    required this.timeSignature,
    required this.stanzas,
    this.chorus,
    this.collection = 'tenzi',
  });

  bool get hasLyrics => stanzas.isNotEmpty;
  bool get isNyimbo => collection == 'nyimbo';

  /// Short label for lists: "T8" for Tenzi, "N123" for Nyimbo.
  String get shortLabel => isNyimbo ? 'N$number' : 'T$number';

  factory TenziHymn.fromJson(Map<String, dynamic> json) {
    final isNyimbo = json['collection']?.toString() == 'nyimbo' ||
        json.containsKey('siteNumber');

    // Nyimbo format: {siteNumber, title, collection, stanzas, chorus?}
    if (isNyimbo) {
      final rawStanzas = json['stanzas'] as List<dynamic>? ?? [];
      return TenziHymn(
        number: json['siteNumber'] is int
            ? json['siteNumber'] as int
            : int.tryParse(json['siteNumber'].toString()) ?? 1,
        title: json['title']?.toString() ?? '',
        category: 'Nyimbo za Kikristo',
        key: '',
        timeSignature: '',
        stanzas: rawStanzas
            .map((s) => TenziStanza.fromJson(s as Map<String, dynamic>))
            .toList(),
        chorus: json['chorus']?.toString(),
        collection: 'nyimbo',
      );
    }

    // Tenzi format: {number, title, category, key, time_signature, stanzas, chorus}
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
      collection: 'tenzi',
    );
  }
}
