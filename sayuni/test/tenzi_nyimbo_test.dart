import 'package:flutter_test/flutter_test.dart';
import 'package:sayuni/features/bible/models/tenzi_model.dart';

void main() {
  group('TenziHymn dual-format parsing', () {
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
      expect(hymn.shortLabel, 'T8');
      expect(hymn.externalUrl, isNull);
    });

    test('Nyimbo format has no lyrics but has external link', () {
      final hymn = TenziHymn.fromJson({
        'siteNumber': 123,
        'title': 'Ninakuhitaji',
        'slug': 'ninakuhitaji',
        'url': 'https://www.mysongbooks.scaptedesigns.com/library/nyimbo-za-kikristo/ninakuhitaji',
        'likes': 5,
        'source': 'MySongbooks — Nyimbo Za Kikristo',
      });

      expect(hymn.number, 123);
      expect(hymn.hasLyrics, isFalse);
      expect(hymn.isNyimbo, isTrue);
      expect(hymn.shortLabel, 'N123');
      expect(hymn.externalUrl, contains('mysongbooks.scaptedesigns.com'));
      expect(hymn.stanzas, isEmpty);
    });
  });
}
