/// Typed media models for the Sayuni audio system.
///
/// Every playable item in the app (live gospel radio, kwaya songs, tenzi za
/// rohoni, mahubiri, bible audio) is described by an [AudioTrack]. The player
/// layer (`audio_service` + `just_audio`) only ever receives [MediaItem]s
/// derived from these models, which keeps notification / lock-screen metadata
/// identical to what the UI renders.
library;

import 'package:audio_service/audio_service.dart';

import '../services/radio_browser_service.dart';

/// The kind of audio content. Drives icons, labels and queue behaviour.
enum MediaType { radio, hymn, choir, sermon, bibleAudio, podcast, worshipSong }

extension MediaTypeX on MediaType {
  /// Swahili label shown to the user.
  String get label {
    switch (this) {
      case MediaType.radio:
        return 'Radio za Injili';
      case MediaType.hymn:
        return 'Tenzi za Rohoni';
      case MediaType.choir:
        return 'Kwaya';
      case MediaType.sermon:
        return 'Mahubiri';
      case MediaType.bibleAudio:
        return 'Biblia Sauti';
      case MediaType.podcast:
        return 'Podcast';
      case MediaType.worshipSong:
        return 'Nyimbo za Ibada';
    }
  }

  /// True for continuous streams: no seek bar, LIVE badge instead.
  bool get isLiveType => this == MediaType.radio;

  static MediaType fromKey(String? key) {
    switch ((key ?? '').toLowerCase().trim()) {
      case 'radio':
        return MediaType.radio;
      case 'hymn':
      case 'tenzi':
        return MediaType.hymn;
      case 'choir':
      case 'kwaya':
        return MediaType.choir;
      case 'sermon':
      case 'mahubiri':
        return MediaType.sermon;
      case 'bible':
      case 'bibleaudio':
      case 'bible_audio':
        return MediaType.bibleAudio;
      case 'podcast':
        return MediaType.podcast;
      default:
        return MediaType.worshipSong;
    }
  }
}

/// A named shelf of content shown as a section inside the player.
class MediaCategory {
  const MediaCategory({
    required this.id,
    required this.label,
    required this.type,
    this.description = '',
    this.liveOnly = false,
  });

  final String id;
  final String label;
  final MediaType type;
  final String description;
  final bool liveOnly;

  static const MediaCategory radio = MediaCategory(
    id: 'radio',
    label: 'Radio za Injili',
    type: MediaType.radio,
    description: 'Redio za Injili za Afrika na kimataifa',
    liveOnly: true,
  );
  static const MediaCategory choir = MediaCategory(
    id: 'choir',
    label: 'Kwaya',
    type: MediaType.choir,
    description: 'Nyimbo za kwaya za Sayuni Jerusalem',
  );
  static const MediaCategory tenzi = MediaCategory(
    id: 'tenzi',
    label: 'Tenzi za Rohoni',
    type: MediaType.hymn,
    description: 'Nyimbo za sifa na kuabudu',
  );
  static const MediaCategory sermons = MediaCategory(
    id: 'sermons',
    label: 'Mahubiri',
    type: MediaType.sermon,
    description: 'Maneno na mafundisho ya wachungaji',
  );
  static const MediaCategory bibleAudio = MediaCategory(
    id: 'bible_audio',
    label: 'Biblia Sauti',
    type: MediaType.bibleAudio,
    description: 'Sauti ya Neno la Mungu',
  );

  /// Sections exposed inside the full-screen player, in display order.
  static const List<MediaCategory> playerSections = <MediaCategory>[
    radio,
    choir,
    tenzi,
    sermons,
    bibleAudio,
  ];
}

/// One playable thing: a radio stream, a song, a sermon recording.
class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.title,
    required this.url,
    required this.category,
    required this.type,
    this.subtitle = '',
    this.artist = '',
    this.artworkUrl,
    this.artworkAsset,
    this.isLive = false,
    this.duration,
    this.bitrate,
    this.tags = const <String>[],
    this.extras = const <String, dynamic>{},
  });

  /// Stable identity. Also used as the playable URI when [url] is a stream.
  final String id;
  final String title;

  /// One-line context, e.g. `Afrika & Kimataifa • Contemporary Gospel`.
  final String subtitle;

  /// Source / artist / church / ministry name.
  final String artist;

  /// Stream or file URL.
  final String url;

  /// Remote artwork (station favicon, sermon thumbnail URL...).
  final String? artworkUrl;

  /// Bundled artwork (`assets/images/...`) used when [artworkUrl] is absent.
  final String? artworkAsset;

  final MediaCategory category;
  final MediaType type;

  /// Live stream -> hide seek bar, show LIVE.
  final bool isLive;

  /// Known length for on-demand content only.
  final Duration? duration;

  /// Stream bitrate in kbps, when known.
  final int? bitrate;

  final List<String> tags;
  final Map<String, dynamic> extras;

  bool get isRadio => type == MediaType.radio;

  /// `Afrika & Kimataifa • Contemporary Gospel • 192kbps`
  /// Remote artwork URL, if the station/track publishes one.
  String? get imageUrl => artworkUrl;

  /// True only for live broadcast streams (seek must be hidden for these).
  bool get isLiveRadio => isLive && type == MediaType.radio;

  String get richSubtitle {
    final parts = <String>[
      if (subtitle.trim().isNotEmpty) subtitle.trim(),
      if (bitrate != null && bitrate! > 0) '${bitrate}kbps',
      if (bitrate == null && tags.isNotEmpty) tags.take(2).join(', '),
    ];
    if (parts.isEmpty) return artist;
    if (artist.isNotEmpty && !parts.first.contains(artist)) {
      parts.insert(0, artist);
    }
    return parts.join(' • ');
  }

  AudioTrack copyWith({String? subtitle, String? artist, String? artworkUrl}) =>
      AudioTrack(
        id: id,
        title: title,
        url: url,
        category: category,
        type: type,
        subtitle: subtitle ?? this.subtitle,
        artist: artist ?? this.artist,
        artworkUrl: artworkUrl ?? this.artworkUrl,
        artworkAsset: artworkAsset,
        isLive: isLive,
        duration: duration,
        bitrate: bitrate,
        tags: tags,
        extras: extras,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'artist': artist,
        'url': url,
        'artworkUrl': artworkUrl,
        'artworkAsset': artworkAsset,
        'categoryId': category.id,
        'type': type.name,
        'isLive': isLive,
        'durationMs': duration?.inMilliseconds,
        'bitrate': bitrate,
        'tags': tags,
      };

  factory AudioTrack.fromMap(Map<String, dynamic> map) {
    final type = MediaTypeX.fromKey(map['type']?.toString());
    return AudioTrack(
      id: map['id']?.toString() ?? map['url']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Bila Jina',
      url: map['url']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      artworkUrl: map['artworkUrl']?.toString(),
      artworkAsset: map['artworkAsset']?.toString(),
      category: _categoryForType(type),
      type: type,
      isLive: map['isLive'] == true || type.isLiveType,
      duration: map['durationMs'] is num
          ? Duration(milliseconds: (map['durationMs'] as num).toInt())
          : null,
      bitrate: map['bitrate'] is num ? (map['bitrate'] as num).toInt() : null,
      tags:
          (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              const <String>[],
    );
  }

  /// The [MediaItem] handed to `audio_service` (notification + lock screen).
  ///
  /// [fallbackArtFileUri] must be a `file://` URI of the church logo produced by
  /// [DefaultArtwork]; `asset://` URIs are not supported by audio_service.
  MediaItem toMediaItem({String? fallbackArtFileUri}) {
    final art = artworkUrl;
    return MediaItem(
      // id must be the playable URL so retries/queue lookups stay unambiguous.
      id: url,
      title: title,
      album: category.label,
      artist: artist.isEmpty ? 'Sayuni Jerusalem Church' : artist,
      genre: type.label,
      artUri: (art != null && art.startsWith('http'))
          ? Uri.parse(art)
          : (fallbackArtFileUri != null ? Uri.parse(fallbackArtFileUri) : null),
      duration: isLive ? null : duration,
      extras: <String, dynamic>{
        'trackId': id,
        'isLive': isLive,
        'categoryId': category.id,
        'mediaType': type.name,
        'streamUrl': url,
        'bitrate': bitrate,
        'subtitle': richSubtitle,
        'artworkUrl': art,
        'artworkAsset': artworkAsset,
        ...extras,
      },
    );
  }

  static MediaCategory _categoryForType(MediaType type) {
    switch (type) {
      case MediaType.radio:
        return MediaCategory.radio;
      case MediaType.choir:
        return MediaCategory.choir;
      case MediaType.hymn:
        return MediaCategory.tenzi;
      case MediaType.sermon:
        return MediaCategory.sermons;
      case MediaType.bibleAudio:
        return MediaCategory.bibleAudio;
      case MediaType.podcast:
      case MediaType.worshipSong:
        return const MediaCategory(
          id: 'worship',
          label: 'Nyimbo za Ibada',
          type: MediaType.worshipSong,
        );
    }
  }
}

extension RadioStationAudio on RadioStation {
  /// Maps a radio-browser station into the app's playable model.
  AudioTrack toAudioTrack() => AudioTrack(
        id: stationuuid,
        title: name,
        subtitle: displaySubtitle,
        artist: country.isEmpty ? 'Radio za Injili' : country,
        url: urlResolved,
        artworkUrl: favicon.startsWith('http') ? favicon : null,
        category: MediaCategory.radio,
        type: MediaType.radio,
        isLive: true,
        bitrate: bitrate > 0 ? bitrate : null,
        tags: tags
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(growable: false),
        extras: <String, dynamic>{
          'stationuuid': stationuuid,
          'homepage': homepage,
          'codec': codec,
          'isCurated': isCurated,
        },
      );
}
