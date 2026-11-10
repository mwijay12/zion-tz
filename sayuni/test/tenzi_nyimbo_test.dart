import 'package:flutter_test/flutter_test.dart';
import 'package:sayuni/features/bible/models/tenzi_model.dart';

void main() {
  group('TenziHymn dual-format parsing (fully offline)', () {
    test('Tenzi format keeps offline lyrics', () {
      final hymn = TenziHymn.fromJson({
        'number': 8,
        'title': 'Chakutumaini Sina',
        'category': 'Imani na Tumaini',
        'key': 'Key of G',
        'time_signature': '4/4',
        'stanzas': [
          {'verse_number': 1, 'text': 'Chakutumaini sina...'},
        ],
        'chorus': 'Kikwagizo...',
      });

      expect(hymn.number, 8);
      expect(hymn.hasLyrics, isTrue);
      expect(hymn.isNyimbo, isFalse);
      expect(hymn.collection, 'tenzi');
      expect(hymn.shortLabel, 'T8');
    });

    test('Nyimbo format carries full offline lyrics and no link fields', () {
      final hymn = TenziHymn.fromJson({
        'siteNumber': 167,
        'title': 'Tumaini Liko',
        'collection': 'nyimbo',
        'stanzas': [
          {'verse_number': 1, 'text': 'Tumaini lililobarikiwa...'},
          {'verse_number': 2, 'text': 'Hii ni hadithi yangu...'},
        ],
        'chorus': 'Hii ni hadithi yangu...',
        'lyricsNote': 'Tafsiri mpya ya wimbo wa zamani (public domain)',
      });

      expect(hymn.number, 167);
      expect(hymn.hasLyrics, isTrue);
      expect(hymn.isNyimbo, isTrue);
      expect(hymn.shortLabel, 'N167');
      expect(hymn.stanzas, hasLength(2));
      expect(hymn.stanzas.first.text, contains('Tumaini'));
      expect(hymn.chorus, contains('hadithi'));
    });

    test('legacy link-only fields are ignored, not turned into URLs', () {
      // Old data used to store a `url`/`slug`/`source`. Parsing must still
      // be safe and must never surface an outbound link.
      final hymn = TenziHymn.fromJson({
        'siteNumber': 123,
        'title': 'Ninakuhitaji',
        'slug': 'ninakuhitaji',
        'url': 'https://example.invalid/hymn',
        'likes': 5,
        'source': 'Legacy index',
      });

      expect(hymn.isNyimbo, isTrue);
      expect(hymn.title, 'Ninakuhitaji');
      expect(hymn.hasLyrics, isFalse);
      expect(hymn.shortLabel, 'N123');
    });
  });
}
