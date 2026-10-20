import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RadioStation {
  final String stationuuid;
  final String name;
  final String urlResolved;
  final String favicon;
  final String country;
  final String countryCode;
  final String tags;
  final String codec;
  final int bitrate;
  final int votes;
  final String state;
  final String homepage;
  final String category; // 'afrogospel' | 'tanzania' | 'global' | 'news'
  final bool isCurated;

  const RadioStation({
    required this.stationuuid,
    required this.name,
    required this.urlResolved,
    this.favicon = '',
    this.country = '',
    this.countryCode = '',
    this.tags = '',
    this.codec = 'MP3',
    this.bitrate = 128,
    this.votes = 0,
    this.state = '',
    this.homepage = '',
    this.category = 'global',
    this.isCurated = false,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json, {String category = 'global'}) {
    final rawUrl = (json['url_resolved'] ?? json['url'] ?? '').toString().trim();
    final name = (json['name'] ?? 'Bila Jina').toString().trim();
    final favicon = (json['favicon'] ?? '').toString().trim();
    final country = (json['country'] ?? '').toString().trim();
    final countryCode = (json['countrycode'] ?? '').toString().trim();
    final tags = (json['tags'] ?? '').toString().trim();
    final codec = (json['codec'] ?? 'MP3').toString().trim();
    final bitrate = int.tryParse(json['bitrate']?.toString() ?? '0') ?? 0;
    final votes = int.tryParse(json['votes']?.toString() ?? '0') ?? 0;
    final state = (json['state'] ?? '').toString().trim();
    final homepage = (json['homepage'] ?? '').toString().trim();
    final stationuuid = (json['stationuuid'] ?? '').toString().trim();

    return RadioStation(
      stationuuid: stationuuid.isNotEmpty ? stationuuid : rawUrl.hashCode.toString(),
      name: name,
      urlResolved: rawUrl,
      favicon: favicon,
      country: country,
      countryCode: countryCode,
      tags: tags,
      codec: codec,
      bitrate: bitrate,
      votes: votes,
      state: state,
      homepage: homepage,
      category: category,
      isCurated: false,
    );
  }

  String get displaySubtitle {
    final parts = <String>[];
    if (country.isNotEmpty) parts.add(country);
    if (state.isNotEmpty && state != country) parts.add(state);
    if (bitrate > 0) parts.add('${bitrate}kbps');
    if (codec.isNotEmpty) parts.add(codec);
    return parts.join(' • ');
  }

  String get flagEmoji {
    final code = countryCode.toUpperCase();
    if (code == 'NG') return '🇳🇬';
    if (code == 'TZ') return '🇹🇿';
    if (code == 'KE') return '🇰🇪';
    if (code == 'UG') return '🇺🇬';
    if (code == 'GH') return '🇬🇭';
    if (code == 'ZA') return '🇿🇦';
    if (code == 'GB' || code == 'UK') return '🇬🇧';
    if (code == 'US') return '🇺🇸';
    if (code == 'FR') return '🇫🇷';
    if (category == 'afrogospel') return '🇳🇬';
    if (category == 'tanzania') return '🇹🇿';
    if (category == 'news') return '📰';
    return '📻';
  }
}

class RadioBrowserService {
  static final RadioBrowserService _instance = RadioBrowserService._internal();
  factory RadioBrowserService() => _instance;
  RadioBrowserService._internal();

  static const List<String> _mirrors = [
    'https://de1.api.radio-browser.info/json',
    'https://de2.api.radio-browser.info/json',
    'https://nl1.api.radio-browser.info/json',
    'https://at1.api.radio-browser.info/json',
  ];

  static const String _userAgent = 'ZionJerusalemApp/1.0.0';

  // In-memory caches to make tab switches instantaneous
  List<RadioStation> _allStationsCache = [];
  final Map<String, List<RadioStation>> _genreCache = {};


  // Guaranteed instant-playing Curated Stations for Afro Gospel (Nigeria & Africa)
  static const List<RadioStation> curatedAfroGospelRadios = [
    RadioStation(
      stationuuid: 'ng-gospel-001',
      name: 'African Gospel Praise Radio',
      urlResolved: 'http://stream.zeno.fm/3fmqr74a7f8uv',
      favicon: 'https://nigeriangospelmusic.com.ng/wp-content/uploads/2022/09/NGM-icon.png',
      country: 'Afrika Mashariki & Kati',
      countryCode: 'AF',
      state: 'Praise & Worship',
      tags: 'gospel, christian, praise, worship',
      codec: 'MP3',
      bitrate: 128,
      votes: 2698,
      category: 'afrogospel',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'ng-gospel-003',
      name: 'Praiseworld Gospel Radio',
      urlResolved: 'https://streaming.radio.co/s7dc18f0ad/listen',
      favicon: 'https://www.praiseworldradio.com/wp-content/uploads/2020/05/praiseworldlogo-1.png',
      country: 'Afrika & Kimataifa',
      countryCode: 'AF',
      state: 'Contemporary Gospel',
      tags: 'christian, contemporary gospel, afro worship',
      codec: 'AAC',
      bitrate: 192,
      votes: 445,
      category: 'afrogospel',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'ng-gospel-008',
      name: 'MCF Radio East Africa',
      urlResolved: 'http://streams.radio.co/s79fbbb432/listen',
      favicon: 'https://mcfradio.co.ug/favicon.ico',
      country: 'Uganda & Afrika Mashariki',
      countryCode: 'UG',
      state: 'Kampala',
      tags: 'christian gospel, worship, neno',
      codec: 'MP3',
      bitrate: 128,
      votes: 1023,
      category: 'afrogospel',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'ng-gospel-006',
      name: 'WiGRadio Worship & Word',
      urlResolved: 'https://stream.zeno.fm/w74w7e91sm8uv',
      favicon: 'https://wigradio.com/favicon.ico',
      country: 'Afrika & Dunia',
      countryCode: 'AF',
      state: 'Worship & Preaching',
      tags: 'gospel, preaching, afro worship',
      codec: 'MP3',
      bitrate: 128,
      votes: 560,
      category: 'afrogospel',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'ng-gospel-007',
      name: 'Adamimogo Prayer & Gospel',
      urlResolved: 'http://stream.zeno.fm/sywy4vua6zhvv',
      favicon: 'https://i0.wp.com/adamimogofm.com/wp-content/uploads/2022/12/logo-removebg-preview-2.png',
      country: 'Afrika',
      countryCode: 'AF',
      state: 'Maombi & Sala',
      tags: 'christian, prayer, apostolic, gospel',
      codec: 'MP3',
      bitrate: 128,
      votes: 682,
      category: 'afrogospel',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'ng-gospel-005',
      name: 'Air Gospel Worship Radio',
      urlResolved: 'https://stream.zeno.fm/qkgrhugy908uv',
      favicon: 'https://airtv.world/favicon.ico',
      country: 'Afrika',
      countryCode: 'AF',
      state: 'Praise & Worship',
      tags: 'gospel, christian talk, praise',
      codec: 'MP3',
      bitrate: 128,
      votes: 200,
      category: 'afrogospel',
      isCurated: true,
    ),
  ];

  // Guaranteed instant-playing Curated Stations for Tanzania Gospel
  static const List<RadioStation> curatedTanzaniaGospelRadios = [
    RadioStation(
      stationuuid: 'tz-gospel-001',
      name: 'Radio Uhai Tanzania',
      urlResolved: 'https://s2.citrus3.com:8050/stream',
      favicon: 'https://www.radiouhai.co.tz/favicon/apple-touch-icon.png',
      country: 'Tanzania',
      countryCode: 'TZ',
      state: 'Tabora & Dar es Salaam',
      tags: 'Christian, Uzima & Tumaini, Swahili Gospel',
      codec: 'AAC',
      bitrate: 128,
      votes: 1912,
      category: 'tanzania',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'tz-gospel-002',
      name: 'Radio Maria Tanzania',
      urlResolved: 'https://dreamsiteradiocp.com:8096/stream',
      favicon: 'https://www.radiomaria.co.tz/wp-content/uploads/2019/07/cropped-radio-maria-logo-192x192.png',
      country: 'Tanzania',
      countryCode: 'TZ',
      state: 'Dar es Salaam',
      tags: 'Ibada, Sala & Neno la Mungu',
      codec: 'MP3',
      bitrate: 128,
      votes: 1850,
      category: 'tanzania',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'tz-gospel-003',
      name: 'Praise Live Global & Africa',
      urlResolved: 'https://stream.streamexperts.com:8062/live',
      favicon: 'https://praiselive.org/wp-content/uploads/2021/08/cropped-favicon-192x192.png',
      country: 'Tanzania / East Africa',
      countryCode: 'TZ',
      state: 'East Africa',
      tags: 'Live Praise & Contemporary Worship 24/7',
      codec: 'MP3',
      bitrate: 128,
      votes: 2150,
      category: 'tanzania',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'tz-gospel-004',
      name: 'WiGRadio Live Africa',
      urlResolved: 'https://stream.zeno.fm/w74w7e91sm8uv',
      favicon: 'https://wigradio.com/favicon.ico',
      country: 'East Africa / Global',
      countryCode: 'TZ',
      state: 'East Africa',
      tags: 'Injili, Mafundisho & Nyimbo za Kuabudu',
      codec: 'MP3',
      bitrate: 128,
      votes: 1620,
      category: 'tanzania',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'tz-gospel-005',
      name: 'Radio Uhai Tanzania',
      urlResolved: 'https://s2.citrus3.com:8050/stream',
      favicon: 'https://www.radiouhai.co.tz/favicon/apple-touch-icon.png',
      country: 'Tanzania',
      countryCode: 'TZ',
      state: 'Tabora & Dar',
      tags: 'Christian, Uzima & Tumaini',
      codec: 'AAC',
      bitrate: 128,
      votes: 912,
      category: 'tanzania',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'tz-gospel-006',
      name: 'Heaven FM Radio',
      urlResolved: 'http://stream.zeno.fm/eequgfw72hhvv',
      favicon: '',
      country: 'Tanzania',
      countryCode: 'TZ',
      state: 'Dar es Salaam',
      tags: 'Gospel Swahili, Kuabudu',
      codec: 'MP3',
      bitrate: 128,
      votes: 459,
      category: 'tanzania',
      isCurated: true,
    ),
  ];

  // Guaranteed instant-playing Curated Stations for Useful News Radio
  static const List<RadioStation> curatedNewsRadios = [
    RadioStation(
      stationuuid: 'news-001',
      name: 'BBC World Service',
      urlResolved: 'http://stream.live.vc.bbcmedia.co.uk/bbc_world_service',
      favicon: 'https://rmp.files.bbci.co.uk/playspace/img/apple-touch-icon.96d5401f35.png',
      country: 'United Kingdom',
      countryCode: 'GB',
      state: 'London',
      tags: 'global news, current affairs, bbc',
      codec: 'MP3',
      bitrate: 64,
      votes: 2730,
      category: 'news',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'news-002',
      name: 'DW News (Kiswahili & English)',
      urlResolved: 'https://dw.audiostream.io/dw/1027/mp3/64/dw08',
      favicon: 'https://www.dw.com/images/icons/favicon-120x120.png',
      country: 'Germany / East Africa',
      countryCode: 'DE',
      state: 'Bonn / Kampala',
      tags: 'habari, swahili news, international',
      codec: 'MP3',
      bitrate: 64,
      votes: 378,
      category: 'news',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'news-003',
      name: 'Radio Mbiu Habari Tanzania',
      urlResolved: 'http://dreamsiteradiocp5.com:8004/stream.mp3',
      favicon: 'https://www.radiombiu.co.tz/favicon.ico',
      country: 'Tanzania',
      countryCode: 'TZ',
      state: 'Dar es Salaam',
      tags: 'habari za tanzania, jamii, taarifa',
      codec: 'MP3',
      bitrate: 64,
      votes: 592,
      category: 'news',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'news-004',
      name: 'RFI Afrique (Habari za Afrika)',
      urlResolved: 'http://live02.rfi.fr/rfiafrique-64.mp3',
      favicon: 'http://www.rfi.fr/apple-touch-icon.png',
      country: 'France / Africa',
      countryCode: 'FR',
      state: 'Paris',
      tags: 'africa news, rfi, habari za dunia',
      codec: 'MP3',
      bitrate: 64,
      votes: 87847,
      category: 'news',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'news-005',
      name: 'KENYA1 FM News & Talkshow',
      urlResolved: 'https://stream.zeno.fm/cmgkmed5u18uv',
      favicon: '',
      country: 'Kenya',
      countryCode: 'KE',
      state: 'Nairobi',
      tags: 'east africa news, swahili, talkshow',
      codec: 'MP3',
      bitrate: 128,
      votes: 283,
      category: 'news',
      isCurated: true,
    ),
    RadioStation(
      stationuuid: 'news-006',
      name: 'BBC World Service East Asia / Africa',
      urlResolved: 'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service_east_asia',
      favicon: 'https://rmp.files.bbci.co.uk/playspace/img/apple-touch-icon.96d5401f35.png',
      country: 'United Kingdom',
      countryCode: 'GB',
      state: 'London',
      tags: 'world news, analysis, bbc radio',
      codec: 'MP3',
      bitrate: 64,
      votes: 2685,
      category: 'news',
      isCurated: true,
    ),
  ];

  /// Queries mirrors in round-robin order with timeout
  Future<List<dynamic>?> _queryApi(String path) async {
    final headers = {'User-Agent': _userAgent};

    for (final mirror in _mirrors) {
      try {
        final uri = Uri.parse('$mirror$path');
        final response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is List) {
            return decoded;
          }
        }
      } catch (e) {
        debugPrint('Radio mirror $mirror error: $e. Trying fallback mirror...');
      }
    }
    return null;
  }

  /// Register station click to keep Radio Browser rankings accurate
  Future<void> registerStationClick(String stationuuid) async {
    if (stationuuid.isEmpty || stationuuid.startsWith('ng-') || stationuuid.startsWith('tz-') || stationuuid.startsWith('news-')) {
      return;
    }
    try {
      final mirror = _mirrors.first;
      final uri = Uri.parse('$mirror/url/$stationuuid');
      await http.get(uri, headers: {'User-Agent': _userAgent}).timeout(const Duration(seconds: 4));
    } catch (_) {
      // Best-effort metric tracking
    }
  }

  /// Fetch Afro Gospel Radio stations (Nigeria + African Gospel)
  Future<List<RadioStation>> fetchAfroGospelRadios() async {
    final results = <RadioStation>[...curatedAfroGospelRadios];
    final seenIds = results.map((r) => r.stationuuid).toSet();
    final seenUrls = results.map((r) => r.urlResolved).toSet();

    try {
      // Query 1: Nigeria Gospel
      final raw1 = await _queryApi(
        '/stations/search?tag=gospel&countrycode=NG&limit=30&hidebroken=true&order=votes&reverse=true',
      );
      if (raw1 != null) {
        for (final item in raw1) {
          final st = RadioStation.fromJson(item, category: 'afrogospel');
          if (st.urlResolved.isNotEmpty && !seenIds.contains(st.stationuuid) && !seenUrls.contains(st.urlResolved)) {
            seenIds.add(st.stationuuid);
            seenUrls.add(st.urlResolved);
            results.add(st);
          }
        }
      }

      // Query 2: Search by Afro Gospel / Afrobeats
      final raw2 = await _queryApi(
        '/stations/search?name=Gospel&countrycode=NG&limit=30&hidebroken=true&order=votes&reverse=true',
      );
      if (raw2 != null) {
        for (final item in raw2) {
          final st = RadioStation.fromJson(item, category: 'afrogospel');
          if (st.urlResolved.isNotEmpty && !seenIds.contains(st.stationuuid) && !seenUrls.contains(st.urlResolved)) {
            seenIds.add(st.stationuuid);
            seenUrls.add(st.urlResolved);
            results.add(st);
          }
        }
      }

      // Query 3: Africa Christian & Worship Radios
      final raw3 = await _queryApi(
        '/stations/search?tag=worship&limit=30&hidebroken=true&order=votes&reverse=true',
      );
      if (raw3 != null) {
        for (final item in raw3) {
          final st = RadioStation.fromJson(item, category: 'afrogospel');
          if (st.urlResolved.isNotEmpty &&
              isGospelOrChristianStation(st) &&
              !seenIds.contains(st.stationuuid) &&
              !seenUrls.contains(st.urlResolved)) {
            seenIds.add(st.stationuuid);
            seenUrls.add(st.urlResolved);
            results.add(st);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching Afro Gospel radios from API: $e');
    }

    return results;
  }

  /// Fetch Tanzania Gospel Radio stations
  Future<List<RadioStation>> fetchTanzaniaGospelRadios() async {
    final results = <RadioStation>[...curatedTanzaniaGospelRadios];
    final seenIds = results.map((r) => r.stationuuid).toSet();
    final seenUrls = results.map((r) => r.urlResolved).toSet();

    try {
      final raw = await _queryApi(
        '/stations/search?countrycode=TZ&limit=30&hidebroken=true&order=votes&reverse=true',
      );
      if (raw != null) {
        for (final item in raw) {
          final st = RadioStation.fromJson(item, category: 'tanzania');
          final tags = st.tags.toLowerCase();
          final name = st.name.toLowerCase();
          // Prioritize gospel/christian/inspirational stations
          if (tags.contains('gospel') ||
              tags.contains('christian') ||
              tags.contains('sayuni') ||
              name.contains('uhai') ||
              name.contains('safina') ||
              name.contains('upendo') ||
              name.contains('wapo') ||
              name.contains('praise') ||
              name.contains('heaven')) {
            if (st.urlResolved.isNotEmpty && !seenIds.contains(st.stationuuid) && !seenUrls.contains(st.urlResolved)) {
              seenIds.add(st.stationuuid);
              seenUrls.add(st.urlResolved);
              results.add(st);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching Tanzania gospel radios from API: $e');
    }

    return results;
  }

  /// Fetch Global Christian / Gospel Radios
  Future<List<RadioStation>> fetchGlobalGospelRadios() async {
    final results = <RadioStation>[];
    final seenIds = <String>{};
    final seenUrls = <String>{};

    try {
      final raw = await _queryApi(
        '/stations/search?tag=gospel&limit=50&hidebroken=true&order=votes&reverse=true',
      );
      if (raw != null) {
        for (final item in raw) {
          final st = RadioStation.fromJson(item, category: 'global');
          if (st.urlResolved.isNotEmpty && !seenIds.contains(st.stationuuid) && !seenUrls.contains(st.urlResolved)) {
            seenIds.add(st.stationuuid);
            seenUrls.add(st.urlResolved);
            results.add(st);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching global gospel radios: $e');
    }

    return results;
  }

  /// Fetch Useful News Radios
  Future<List<RadioStation>> fetchNewsRadios() async {
    final results = <RadioStation>[...curatedNewsRadios];
    final seenIds = results.map((r) => r.stationuuid).toSet();
    final seenUrls = results.map((r) => r.urlResolved).toSet();

    try {
      final raw = await _queryApi(
        '/stations/search?tag=news&language=swahili&limit=25&hidebroken=true&order=votes&reverse=true',
      );
      if (raw != null) {
        for (final item in raw) {
          final st = RadioStation.fromJson(item, category: 'news');
          if (st.urlResolved.isNotEmpty && !seenIds.contains(st.stationuuid) && !seenUrls.contains(st.urlResolved)) {
            seenIds.add(st.stationuuid);
            seenUrls.add(st.urlResolved);
            results.add(st);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching news radios from API: $e');
    }

    return results;
  }

  /// Static validator to ensure only true Christian / Gospel stations are shown
  static bool isGospelOrChristianStation(RadioStation st) {
    final t = st.tags.toLowerCase();
    final n = st.name.toLowerCase();

    // 1. Exclude non-gospel, secular, hindi, bollywood, islam, secular rap/metal, etc.
    const badWords = [
      'hindi', 'bollywood', 'islam', 'quran', 'koran', 'deshi', 'punjabi',
      'arabic', 'mosque', 'secular', 'heavy metal', 'edm', 'club', 'dancehall',
      'nightclub', 'adult', 'dating', 'tarab', 'taarab'
    ];
    for (final bad in badWords) {
      if (t.contains(bad) || n.contains(bad)) {
        return false;
      }
    }

    // 2. Must match positive Christian / Gospel indicator
    const goodWords = [
      'gospel', 'christian', 'worship', 'praise', 'church', 'jesus', 'christ',
      'bible', 'sayuni', 'uhai', 'maria', 'hallelujah', 'amen', 'pastor', 'bishop',
      'choir', 'kwaya', 'tenzi', 'roho', 'faith', 'hope', 'inspirational', 'swahili'
    ];
    for (final good in goodWords) {
      if (t.contains(good) || n.contains(good)) {
        return true;
      }
    }
    return false;
  }

  /// Fetch 1,000+ Top Live Gospel Radio Stations across the world (Strictly Gospel & Christian)
  Future<List<RadioStation>> fetchAllTopStations({int limit = 1000, bool forceRefresh = false}) async {
    if (!forceRefresh && _allStationsCache.isNotEmpty) {
      return _allStationsCache;
    }

    try {
      final raw = await _queryApi(
        '/stations/search?tag=gospel&hidebroken=true&order=votes&reverse=true&limit=$limit',
      );
      if (raw != null && raw.isNotEmpty) {
        final results = <RadioStation>[];
        final seenIds = <String>{};
        final seenUrls = <String>{};

        for (final item in raw) {
          final st = RadioStation.fromJson(item, category: 'all');
          if (st.urlResolved.isNotEmpty && 
              isGospelOrChristianStation(st) &&
              !seenIds.contains(st.stationuuid) && 
              !seenUrls.contains(st.urlResolved)) {
            seenIds.add(st.stationuuid);
            seenUrls.add(st.urlResolved);
            results.add(st);
          }
        }

        // If we want even more stations, query christian worship
        final rawWorship = await _queryApi(
          '/stations/search?tag=worship&hidebroken=true&order=votes&reverse=true&limit=200',
        );
        if (rawWorship != null) {
          for (final item in rawWorship) {
            final st = RadioStation.fromJson(item, category: 'all');
            if (st.urlResolved.isNotEmpty && 
                isGospelOrChristianStation(st) &&
                !seenIds.contains(st.stationuuid) && 
                !seenUrls.contains(st.urlResolved)) {
              seenIds.add(st.stationuuid);
              seenUrls.add(st.urlResolved);
              results.add(st);
            }
          }
        }

        if (results.isNotEmpty) {
          _allStationsCache = results;
          return results;
        }
      }
    } catch (e) {
      debugPrint('Error fetching top gospel radio stations: $e');
    }

    // Fallback if network fails
    if (_allStationsCache.isNotEmpty) return _allStationsCache;
    return [
      ...curatedAfroGospelRadios,
      ...curatedTanzaniaGospelRadios,
      ...curatedNewsRadios,
    ];
  }

  /// Fetch stations by Tag/Genre (e.g. pop, jazz, classical, reggae, etc.)
  Future<List<RadioStation>> fetchStationsByGenre(String tag, {int limit = 200}) async {
    final key = tag.toLowerCase().trim();
    if (_genreCache.containsKey(key) && _genreCache[key]!.isNotEmpty) {
      return _genreCache[key]!;
    }

    try {
      final encoded = Uri.encodeQueryComponent(key);
      final raw = await _queryApi(
        '/stations/search?tag=$encoded&hidebroken=true&order=votes&reverse=true&limit=$limit',
      );
      if (raw != null && raw.isNotEmpty) {
        final results = <RadioStation>[];
        final seenIds = <String>{};
        final seenUrls = <String>{};

        for (final item in raw) {
          final st = RadioStation.fromJson(item, category: key);
          if (st.urlResolved.isNotEmpty && 
              isGospelOrChristianStation(st) &&
              !seenIds.contains(st.stationuuid) && 
              !seenUrls.contains(st.urlResolved)) {
            seenIds.add(st.stationuuid);
            seenUrls.add(st.urlResolved);
            results.add(st);
          }
        }

        if (results.isNotEmpty) {
          _genreCache[key] = results;
          return results;
        }
      }
    } catch (e) {
      debugPrint('Error fetching stations for genre $tag: $e');
    }
    return [];
  }

  /// Live Search across Gospel stations (returns up to 100 matches)
  Future<List<RadioStation>> searchStations(String query) async {
    if (query.trim().isEmpty) return [];

    final results = <RadioStation>[];
    final seenUrls = <String>{};

    try {
      final encoded = Uri.encodeQueryComponent(query.trim());
      final raw = await _queryApi(
        '/stations/search?name=$encoded&limit=100&hidebroken=true&order=votes&reverse=true',
      );
      if (raw != null) {
        for (final item in raw) {
          final st = RadioStation.fromJson(item, category: 'search');
          if (st.urlResolved.isNotEmpty && 
              isGospelOrChristianStation(st) &&
              !seenUrls.contains(st.urlResolved)) {
            seenUrls.add(st.urlResolved);
            results.add(st);
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching stations: $e');
    }

    return results;
  }
}
