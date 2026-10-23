import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../media/default_artwork.dart';
import '../media/media_models.dart';
import 'audio_handler.dart';
import 'radio_browser_service.dart';

/// A gospel radio station from the bundled catalogue.
class GospelRadioStation {
  final String id;
  final String name;
  final String location;
  final String streamUrl;
  final String tag;
  final String iconEmoji;

  const GospelRadioStation({
    required this.id,
    required this.name,
    required this.location,
    required this.streamUrl,
    required this.tag,
    required this.iconEmoji,
  });
}

/// Legacy view of "what is playing right now", kept so older screens compile.
///
/// New code should use [AudioTrack] instead.
class CurrentMediaTrack {
  final String id;
  final String title;
  final String subtitle;
  final String audioUrl;
  final String? imageUrl;
  final bool isLiveRadio;

  const CurrentMediaTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.audioUrl,
    this.imageUrl,
    this.isLiveRadio = false,
  });

  AudioTrack toAudioTrack() => AudioTrack(
        id: id,
        title: title,
        subtitle: subtitle,
        artist: 'Sayuni Jerusalem Church',
        url: audioUrl,
        artworkUrl: imageUrl,
        category: isLiveRadio ? MediaCategory.radio : MediaCategory.sermons,
        type: isLiveRadio ? MediaType.radio : MediaType.sermon,
        isLive: isLiveRadio,
      );

  MediaItem toMediaItem() => toAudioTrack().toMediaItem();
}

/// App-wide audio facade.
///
/// The UI never touches `just_audio` directly: it reads [playbackState],
/// [mediaItem], [positionStream], [errorStream] and [currentTrack] here, while
/// [ZionAudioHandler] owns the single player instance. Playback therefore keeps
/// running across navigation, widget disposal and backgrounding.
class ChurchAudioService extends ChangeNotifier {
  static final ChurchAudioService _instance = ChurchAudioService._internal();
  factory ChurchAudioService() => _instance;

  ChurchAudioService._internal();

  static ZionAudioHandler? _handler;
  static Future<void>? _initFuture;
  static String? _initError;
  static bool _platformSessionActive = false;

  /// Android channel reused by the media notification and the app's own alerts.
  static const String notificationChannelId = 'com.zion.church.audio';
  static const String notificationChannelName = 'Sayuni Media & Audio';
  static const String notificationChannelDescription =
      'Udhibiti wa sauti na redio ya Sayuni kwenye lock screen';

  AudioTrack? _currentTrack;
  List<AudioTrack> _queue = const <AudioTrack>[];
  int _queueIndex = 0;
  PlaybackState _playbackState = PlaybackState();
  MediaItem? _mediaItem;
  Duration _duration = Duration.zero;
  bool _audioFailed = false;
  Timer? _ticker;

  final PublishSubject<Duration> _positionSubject = PublishSubject<Duration>();
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  // ------------------------------------------------------------- bootstrap

  /// Registers the handler with `audio_service` on Android/iOS, or runs the bare
  /// player on web (where `audio_service` has no platform implementation).
  ///
  /// Never throws and never leaves the UI hanging: if registration fails the app
  /// still plays audio in the foreground and [initError] explains why.
  static Future<void> init() {
    final pending = _initFuture;
    if (pending != null) return pending;
    final future = _bootstrap();
    _initFuture = future;
    return future;
  }

  static Future<void> _bootstrap() async {
    await DefaultArtwork.warmUp();
    try {
      if (kIsWeb) {
        final handler = ZionAudioHandler();
        await handler.boot();
        _handler = handler;
        _platformSessionActive = false;
        return;
      }
      final handler = await AudioService.init<ZionAudioHandler>(
        builder: () => ZionAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: notificationChannelId,
          androidNotificationChannelName: notificationChannelName,
          androidNotificationChannelDescription: notificationChannelDescription,
          androidNotificationIcon: 'drawable/ic_notification',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationClickStartsActivity: true,
          androidResumeOnClick: true,
          artDownscaleWidth: 512,
          artDownscaleHeight: 512,
          notificationColor: Color(0xFF0D52CD),
        ),
      );
      await handler.boot();
      handler.backgroundActive = true;
      _handler = handler;
      _platformSessionActive = true;
    } catch (e) {
      // Fallback: keep audio working without the platform media session.
      debugPrint('AudioService.init failed, falling back to local player: $e');
      _initError = e.toString();
      try {
        final handler = ZionAudioHandler();
        await handler.boot();
        _handler = handler;
        _platformSessionActive = false;
      } catch (e2) {
        debugPrint('Local audio fallback failed too: $e2');
        _handler = null;
      }
    }
  }

  /// Asks for `POST_NOTIFICATIONS` (Android 13+) so the media notification and
  /// the lock-screen controls can be displayed. Idempotent: the system shows the
  /// prompt once and afterwards only reports the stored decision.
  ///
  /// Returns `true` when notifications are allowed (always `true` on iOS/web,
  /// where audio_service does not need a runtime permission for media playback).
  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } catch (e) {
      debugPrint('Notification permission request skipped: $e');
      return true;
    }
  }

  static bool get isReady => _handler != null;
  static bool get platformSessionActive => _platformSessionActive;
  static String? get initError => _initError;

  // ------------------------------------------------------------------ state

  /// Everything the player UI needs, in one object.
  PlayerSnapshot get snapshot => PlayerSnapshot(
        track: _currentTrack,
        playing: _playbackState.playing,
        buffering:
            _playbackState.processingState == AudioProcessingState.buffering ||
                _playbackState.processingState == AudioProcessingState.loading,
        failed: _playbackState.processingState == AudioProcessingState.error,
        errorMessage: _handler?.errorMessage,
        position: position,
        duration: _duration,
        hasPrevious: _queue.length > 1,
        hasNext: _queue.length > 1,
        queueLength: _queue.length,
        index: _queueIndex,
        backgroundActive: _platformSessionActive,
      );

  AudioTrack? get currentTrack => _currentTrack;
  List<AudioTrack> get queueTracks => _queue;
  int get queueIndex => _queueIndex;
  bool get hasActiveTrack => _currentTrack != null;
  bool get isPlaying => _playbackState.playing;
  bool get isLoading => snapshot.buffering || _audioFailed;
  bool get hasError => snapshot.failed;
  String? get errorMessage => _handler?.errorMessage;
  Duration get position => _handler?.position ?? Duration.zero;
  Duration get duration => _duration;
  bool get hasNext => _queue.length > 1;
  bool get hasPrevious => _queue.length > 1;
  bool get isLive => _currentTrack?.isLive ?? false;
  Stream<Duration> get positionStream => _positionSubject.stream;

  /// Legacy API kept for existing screens.
  static const List<GospelRadioStation> gospelRadios = <GospelRadioStation>[
    GospelRadioStation(
      id: 'praiseworld-ng',
      name: 'Praiseworld Radio',
      location: 'Lagos, Nigeria',
      streamUrl: 'https://streaming.radio.co/s7dc18f0ad/listen',
      tag: 'Afro Gospel, Praise & Worship 24/7',
      iconEmoji: '\u{1F1F3}',
    ),
    GospelRadioStation(
      id: 'gospotainment-live',
      name: 'Gospotainment Radio',
      location: 'West Africa',
      streamUrl: 'https://radio.gotright.net/radio/8000/radio.mp3',
      tag: 'Afrobeats Gospel Hits',
      iconEmoji: '\u{1F525}',
    ),
    GospelRadioStation(
      id: 'wigradio-live',
      name: 'WiGRadio Live',
      location: 'Africa & Global',
      streamUrl: 'https://stream.zeno.fm/w74w7e91sm8uv',
      tag: 'Christian Talk, Worship & Injili',
      iconEmoji: '\u{1F54A}',
    ),
  ];

  /// Attaches the handler streams. Called once from the app bootstrap, and safe
  /// to call again after a failed init.
  Future<void> bind() async {
    await init();
    final handler = _handler;
    if (handler == null || _subscriptions.isNotEmpty) return;

    _subscriptions.add(handler.playbackState.listen((state) {
      _playbackState = state;
      _notify();
    }));
    _subscriptions.add(handler.mediaItem.listen((item) {
      _mediaItem = item;
      _duration = item?.duration ?? Duration.zero;
      final track = _trackFor(item);
      if (track != null) _currentTrack = track;
      _syncTicker();
      _notify();
    }));
    _subscriptions.add(handler.errorStream.listen((message) {
      _audioFailed = message != null;
      _notify();
    }));
    _subscriptions.add(handler.positionStream
        .listen((position) => _positionSubject.add(position)));
    _notify();
  }

  AudioTrack? _trackFor(MediaItem? item) {
    if (item == null) return null;
    for (final track in _queue) {
      if (track.url == item.id) return track;
    }
    if (_currentTrack != null && _currentTrack!.url == item.id)
      return _currentTrack;
    return AudioTrack.fromMap(<String, dynamic>{
      'id': item.extras?['trackId'] ?? item.id,
      'title': item.title,
      'url': item.id,
      'subtitle': item.extras?['subtitle'] ?? item.album ?? '',
      'artist': item.artist ?? '',
      'artworkUrl': item.extras?['artworkUrl'],
      'artworkAsset': item.extras?['artworkAsset'],
      'type': item.extras?['mediaType'] ?? 'radio',
      'isLive': item.extras?['isLive'] == true,
      'bitrate': item.extras?['bitrate'],
    });
  }

  void _syncTicker() {
    final shouldTick = _playbackState.playing && !isLive;
    if (shouldTick && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _positionSubject.add(position);
        notifyListeners();
      });
    } else if (!shouldTick) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _notify() {
    _syncTicker();
    notifyListeners();
  }

  // --------------------------------------------------------------- commands

  /// Plays a list of tracks starting at [startIndex]; next/previous walk the
  /// same list, which is what the queue sheet shows.
  Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {
    final playable = tracks.where((t) => t.url.trim().isNotEmpty).toList();
    if (playable.isEmpty) {
      _audioFailed = true;
      _notify();
      return;
    }
    _audioFailed = false;
    _queue = playable;
    _queueIndex = startIndex.clamp(0, playable.length - 1);
    _currentTrack = playable[_queueIndex];
    _notify();
    final handler = _handler;
    if (handler == null) return;
    await handler.playQueue(
      <MediaItem>[
        for (final t in playable)
          t.toMediaItem(fallbackArtFileUri: DefaultArtwork.fileUri),
      ],
      _queueIndex,
    );
  }

  /// Legacy: plays a single item and makes it the whole queue.
  Future<void> playTrackItem(CurrentMediaTrack track) =>
      playQueue(<AudioTrack>[track.toAudioTrack()]);

  Future<void> playTrack({
    required String id,
    required String title,
    required String subtitle,
    required String audioUrl,
    String? imageUrl,
    bool isLiveRadio = false,
    String? artist,
    MediaType type = MediaType.sermon,
    Duration? duration,
  }) =>
      playQueue(<AudioTrack>[
        AudioTrack(
          id: id,
          title: title,
          subtitle: subtitle,
          artist: artist ?? 'Sayuni Jerusalem Church',
          url: audioUrl,
          artworkUrl:
              imageUrl != null && imageUrl.startsWith('http') ? imageUrl : null,
          artworkAsset: imageUrl != null && imageUrl.startsWith('assets')
              ? imageUrl
              : null,
          category: isLiveRadio ? MediaCategory.radio : MediaCategory.sermons,
          type: isLiveRadio ? MediaType.radio : type,
          isLive: isLiveRadio,
          duration: duration,
        ),
      ]);

  Future<void> playRadioStation(GospelRadioStation station) => playQueue(
        <AudioTrack>[
          for (final s in gospelRadios)
            AudioTrack(
              id: s.id,
              title: s.name,
              subtitle: '${s.location} • ${s.tag}',
              artist: s.location,
              url: s.streamUrl,
              category: MediaCategory.radio,
              type: MediaType.radio,
              isLive: true,
            ),
        ],
        startIndex: gospelRadios.indexWhere((s) => s.id == station.id),
      );

  /// Plays a station from the radio-browser catalogue, with the whole visible
  /// list as the queue so next/previous cycle through stations.
  Future<void> playRadioBrowserStation(
    RadioStation station, {
    List<RadioStation> contextStations = const <RadioStation>[],
  }) async {
    final list =
        contextStations.any((s) => s.stationuuid == station.stationuuid)
            ? contextStations
            : <RadioStation>[station];
    final index = list.indexWhere((s) => s.stationuuid == station.stationuuid);
    await playQueue(
      <AudioTrack>[for (final s in list) s.toAudioTrack()],
      startIndex: index < 0 ? 0 : index,
    );
  }

  Future<void> togglePlayPause() async {
    final handler = _handler;
    if (handler == null) return;
    if (handler.isPlaying) {
      await handler.pause();
    } else {
      await handler.retryCurrent();
    }
    _notify();
  }

  Future<void> playNext() async {
    final handler = _handler;
    if (handler == null) return;
    await handler.skipToNext();
    _queueIndex = handler.currentIndex;
    if (_queueIndex >= 0 && _queueIndex < _queue.length) {
      _currentTrack = _queue[_queueIndex];
    }
    _notify();
  }

  Future<void> playPrevious() async {
    final handler = _handler;
    if (handler == null) return;
    await handler.skipToPrevious();
    _queueIndex = handler.currentIndex;
    if (_queueIndex >= 0 && _queueIndex < _queue.length) {
      _currentTrack = _queue[_queueIndex];
    }
    _notify();
  }

  Future<void> seek(Duration newPosition) async {
    if (isLive) return;
    await _handler?.seek(newPosition);
    _positionSubject.add(newPosition);
    _notify();
  }

  Future<void> setVolume(double value) =>
      _handler?.setVolume(value) ?? Future<void>.value();

  /// Re-opens the failed stream without changing the queue.
  Future<void> retry() async {
    _audioFailed = false;
    _notify();
    await _handler?.retryCurrent();
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _ticker = null;
    await _handler?.stop();
    _currentTrack = null;
    _mediaItem = null;
    _queue = const <AudioTrack>[];
    _queueIndex = 0;
    _audioFailed = false;
    notifyListeners();
  }

  /// Opens the platform media controls without starting new audio (used when the
  /// user taps the mini-player while paused).
  MediaItem? get mediaItem => _mediaItem;

  @override
  void dispose() {
    // Intentionally does NOT stop playback: this facade is a singleton and audio
    // must outlive any widget that listened to it.
    super.dispose();
  }

  @visibleForTesting
  static Future<void> resetForTest() async {
    await _handler?.dispose();
    _handler = null;
    _initFuture = null;
  }
}

/// Immutable view of the player, rendered by the mini-player and full screen.
class PlayerSnapshot {
  const PlayerSnapshot({
    required this.track,
    required this.playing,
    required this.buffering,
    required this.failed,
    required this.position,
    required this.duration,
    required this.hasPrevious,
    required this.hasNext,
    required this.queueLength,
    required this.index,
    required this.backgroundActive,
    this.errorMessage,
  });

  final AudioTrack? track;
  final bool playing;
  final bool buffering;
  final bool failed;
  final String? errorMessage;
  final Duration position;
  final Duration duration;
  final bool hasPrevious;
  final bool hasNext;
  final int queueLength;
  final int index;
  final bool backgroundActive;

  bool get hasTrack => track != null;
  bool get isLive => track?.isLive ?? false;

  /// Elapsed/total text for the seek row.
  String get elapsedLabel => _fmt(position);
  String get remainingLabel =>
      duration <= Duration.zero ? 'LIVE' : _fmt(duration);

  static String _fmt(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
