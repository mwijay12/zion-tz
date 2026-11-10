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

/// A hymn in either collection:
/// - **Tenzi za Rohoni** (`collection == 'tenzi'`): bundled offline with
///   full lyrics (`stanzas` non-empty, `hasLyrics == true`).
/// - **Nyimbo za Kikristo** (`collection == 'nyimbo'`): indexed from
///   MySongbooks (mysongbooks.scaptedesigns.com) — title + link only,
///   no lyrics bundled (`stanzas` empty, `externalUrl` set). Full
///   lyrics/audio open on MySongbooks via the link.
///
/// Only titles/numbers/URLs are indexed for Nyimbo — lyrics are never
/// copied from the website (copyright). See
/// `assets/hymns/nyimbo_za_kikristo.json` header note in docs.
class TenziHymn {
  final int number;
  final String title;
  final String category;
  final String key;
  final String timeSignature;
  final List<TenziStanza> stanzas;
  final String? chorus;

  /// 'tenzi' (offline lyrics) or 'nyimbo' (MySongbooks index).
  final String collection;

  /// MySongbooks URL for Nyimbo entries (null for Tenzi).
  final String? externalUrl;

  /// Likes on MySongbooks (Nyimbo only, for "popular" sorting).
  final int likes;

  const TenziHymn({
    required this.number,
    required this.title,
    required this.category,
    required this.key,
    required this.timeSignature,
    required this.stanzas,
    this.chorus,
    this.collection = 'tenzi',
    this.externalUrl,
    this.likes = 0,
  });

  bool get hasLyrics => stanzas.isNotEmpty;
  bool get isNyimbo => collection == 'nyimbo';

  /// Short label for lists: "T8" for Tenzi, "N123" for Nyimbo.
  String get shortLabel => isNyimbo ? 'N$number' : 'T$number';

  factory TenziHymn.fromJson(Map<String, dynamic> json) {
    // Nyimbo format: {siteNumber, title, slug, url, likes, source}
    if (json.containsKey('siteNumber') || json.containsKey('url')) {
      return TenziHymn(
        number: json['siteNumber'] is int
            ? json['siteNumber'] as int
            : int.tryParse(json['siteNumber'].toString()) ?? 1,
        title: json['title']?.toString() ?? '',
        category: 'Nyimbo za Kikristo',
        key: '',
        timeSignature: '',
        stanzas: const [],
        collection: 'nyimbo',
        externalUrl: json['url']?.toString(),
        likes: json['likes'] is int
            ? json['likes'] as int
            : int.tryParse(json['likes'].toString()) ?? 0,
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
