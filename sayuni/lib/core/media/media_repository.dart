import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/church_customization_service.dart';
import '../services/radio_browser_service.dart';
import 'media_models.dart';

/// Reads the audio catalogue for the player.
///
/// The app already has a backend bridge (the Sayuni web portal pushes sermons /
/// media through [ChurchCustomizationService], and admin uploads are cached in
/// SharedPreferences), so this repository merges:
///
/// 1. Live gospel radio from radio-browser.info (curated + search).
/// 2. Uploaded church audio (sermons, kwaya, teaching) from the portal bridge.
/// 3. A small bundled fallback catalogue so the player is never empty offline.
///
/// Swapping in Firebase/Supabase later only requires another [MediaRepository]
/// implementation returning the same [AudioTrack] list - the player, queue,
/// notification and mini-player code do not change.
abstract class MediaRepository {
  const MediaRepository();

  /// Live radio stations, optionally filtered by [query]/[category].
  Future<List<AudioTrack>> radioStations({String? query, String? category});

  /// On-demand church audio for a category (kwaya, tenzi, mahubiri, bible).
  Future<List<AudioTrack>> tracksIn(MediaCategory category, {String? query});

  /// Everything the player can show right now, grouped by section.
  Future<Map<MediaCategory, List<AudioTrack>>> catalogue();
}

/// Default repository used by the app.
class SayuniMediaRepository extends MediaRepository {
  SayuniMediaRepository(
      {RadioBrowserService? radioService,
      ChurchCustomizationService? customizationService})
      : _radio = radioService ?? RadioBrowserService(),
        _portal = customizationService ?? ChurchCustomizationService();

  final RadioBrowserService _radio;
  final ChurchCustomizationService _portal;

  static final SayuniMediaRepository instance = SayuniMediaRepository();

  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  @override
  Future<List<AudioTrack>> radioStations(
      {String? query, String? category}) async {
    final key = 'radio:${category ?? 'all'}';
    final cached = _cache[key];
    if (cached != null && !cached.isStale && (query == null || query.isEmpty)) {
      return cached.tracks;
    }

    List<RadioStation> source;
    final trimmed = (query ?? '').trim();
    try {
      if (trimmed.isNotEmpty) {
        source = await _radio
            .fetchStationsByGenre(trimmed, limit: 60)
            .timeout(_fetchTimeout);
      } else {
        source = <RadioStation>[
          ...RadioBrowserService.curatedAfroGospelRadios,
          ...RadioBrowserService.curatedTanzaniaGospelRadios,
          ...RadioBrowserService.curatedNewsRadios,
        ];
      }
    } catch (e) {
      debugPrint('MediaRepository radio fetch failed: $e');
      // Offline / blocked network: curated list is bundled in the app, so use it.
      source = <RadioStation>[
        ...RadioBrowserService.curatedAfroGospelRadios,
        ...RadioBrowserService.curatedTanzaniaGospelRadios,
      ];
    }

    final tracks = <AudioTrack>[
      for (final s in source)
        if (s.urlResolved.trim().isNotEmpty) s.toAudioTrack(),
    ];
    _cache[key] = _CacheEntry(tracks);
    return tracks;
  }

  @override
  Future<List<AudioTrack>> tracksIn(MediaCategory category,
      {String? query}) async {
    switch (category.type) {
      case MediaType.radio:
        return radioStations(query: query);
      case MediaType.hymn:
        final tracks = await _loadUploaded();
        return tracks
            .where((t) =>
                _matches(t, 'tenzi') ||
                _matches(t, 'hymn') ||
                _matches(t, 'nyimbo'))
            .toList();
      case MediaType.choir:
        final tracks = await _loadUploaded();
        return tracks
            .where((t) => _matches(t, 'kwaya') || _matches(t, 'choir'))
            .toList();
      case MediaType.sermon:
      case MediaType.podcast:
      case MediaType.worshipSong:
        final tracks = await _loadUploaded();
        return tracks
            .where((t) =>
                t.type == MediaType.sermon || t.type == MediaType.worshipSong)
            .toList();
      case MediaType.bibleAudio:
        return const <AudioTrack>[];
    }
  }

  @override
  Future<Map<MediaCategory, List<AudioTrack>>> catalogue() async {
    final result = <MediaCategory, List<AudioTrack>>{};
    for (final section in MediaCategory.playerSections) {
      result[section] = await tracksIn(section);
    }
    return result;
  }

  static const Duration _fetchTimeout = Duration(seconds: 12);

  bool _matches(AudioTrack track, String needle) =>
      track.tags.any((t) => t.toLowerCase().contains(needle)) ||
      track.category.id.toLowerCase().contains(needle) ||
      track.subtitle.toLowerCase().contains(needle) ||
      track.artist.toLowerCase().contains(needle);

  /// Portal + admin uploads already available in the app.
  Future<List<AudioTrack>> _loadUploaded() async {
    final tracks = <AudioTrack>[];
    final seen = <String>{};

    void add(AudioTrack t) {
      if (t.url.trim().isEmpty) return;
      if (!seen.add(t.id)) return;
      tracks.add(t);
    }

    try {
      for (final s in _portal.customSermons) {
        add(AudioTrack(
          id: s.id,
          title: s.title,
          subtitle: s.scripture.isEmpty
              ? s.category
              : '${s.preacher} • ${s.scripture}',
          artist: s.preacher.isEmpty ? 'Sayuni Jerusalem Church' : s.preacher,
          url: s.mediaUrl,
          artworkUrl: s.thumbnailUrl,
          artworkAsset: 'assets/images/church_front.jpg',
          category: _categoryOf(s.category),
          type: MediaTypeX.fromKey(s.category),
          duration: _parseDuration(s.duration),
        ));
      }
    } catch (e) {
      debugPrint('MediaRepository portal read failed: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('zion_admin_uploaded_media');
      if (raw != null && raw.isNotEmpty) {
        for (final e in jsonDecode(raw) as List<dynamic>) {
          final map = Map<String, dynamic>.from(e as Map);
          final url = (map['audioUrl'] ?? map['videoUrl'] ?? '').toString();
          if (url.isEmpty) continue;
          final category = (map['category'] ?? 'Mahubiri').toString();
          add(AudioTrack(
            id: (map['id'] ?? url).toString(),
            title: (map['title'] ?? 'Rekodi ya Sayuni').toString(),
            subtitle: (map['description'] ?? category).toString(),
            artist: (map['preacher'] ?? 'Sayuni Jerusalem Church').toString(),
            url: url,
            artworkUrl: (map['imageUrl'] ?? '').toString().startsWith('http')
                ? map['imageUrl'].toString()
                : null,
            artworkAsset: 'assets/images/church_front.jpg',
            category: _categoryOf(category),
            type: MediaTypeX.fromKey(category),
            duration: _parseDuration((map['duration'] ?? '').toString()),
          ));
        }
      }
    } catch (e) {
      debugPrint('MediaRepository local read failed: $e');
    }

    return tracks;
  }

  MediaCategory _categoryOf(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('kwaya') || lower.contains('choir'))
      return MediaCategory.choir;
    if (lower.contains('tenzi') ||
        lower.contains('hymn') ||
        lower.contains('nyimbo')) return MediaCategory.tenzi;
    if (lower.contains('biblia') || lower.contains('bible'))
      return MediaCategory.bibleAudio;
    if (lower.contains('radio') || lower.contains('redio'))
      return MediaCategory.radio;
    return MediaCategory.sermons;
  }

  static Duration? _parseDuration(String raw) {
    final match = RegExp(r'(\d+)\s*[:min]+\s*(\d+)?').firstMatch(raw.trim());
    if (match == null) return null;
    final a = int.tryParse(match.group(1) ?? '');
    final b = int.tryParse(match.group(2) ?? '');
    if (a == null) return null;
    if (raw.contains(':') && b != null) return Duration(minutes: a, seconds: b);
    return Duration(minutes: a);
  }
}

class _CacheEntry {
  _CacheEntry(this.tracks) : stamp = DateTime.now();
  final List<AudioTrack> tracks;
  final DateTime stamp;
  bool get isStale =>
      DateTime.now().difference(stamp) > const Duration(minutes: 10);
}
