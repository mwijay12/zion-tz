class BibleVerse {
  final String verseNumber;
  final String verseText;

  const BibleVerse({
    required this.verseNumber,
    required this.verseText,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      verseNumber: json['verse_number']?.toString() ?? '',
      verseText: (json['verse_text']?.toString() ?? '').trim(),
    );
  }
}

class BibleChapter {
  final String chapterNumber;
  final List<BibleVerse> verses;

  const BibleChapter({
    required this.chapterNumber,
    required this.verses,
  });

  factory BibleChapter.fromJson(Map<String, dynamic> json) {
    List<dynamic> rawVerses = [];
    final v = json['VERSES'] ?? json['VERSE'];
    if (v is List) {
      rawVerses = v;
    } else if (v is Map) {
      rawVerses = [v];
    }

    return BibleChapter(
      chapterNumber: json['chapter_number']?.toString() ?? '',
      verses: rawVerses
          .whereType<Map<String, dynamic>>()
          .map((v) => BibleVerse.fromJson(v))
          .toList(),
    );
  }
}

class BibleBook {
  final String bookNumber;
  final String bookName;
  final List<BibleChapter> chapters;

  const BibleBook({
    required this.bookNumber,
    required this.bookName,
    required this.chapters,
  });

  bool get isNewTestament {
    final num = int.tryParse(bookNumber) ?? 1;
    return num >= 40;
  }

  String get testament => isNewTestament ? 'Agano Jipya' : 'Agano la Kale';

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    List<dynamic> rawChapters = [];
    final c = json['CHAPTER'];
    if (c is List) {
      rawChapters = c;
    } else if (c is Map) {
      rawChapters = [c];
    }

    return BibleBook(
      bookNumber: json['book_number']?.toString() ?? '',
      bookName: json['book_name']?.toString() ?? '',
      chapters: rawChapters
          .whereType<Map<String, dynamic>>()
          .map((c) => BibleChapter.fromJson(c))
          .toList(),
    );
  }
}
