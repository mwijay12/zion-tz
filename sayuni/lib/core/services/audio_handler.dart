import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../media/media_models.dart';

/// The single owner of audio playback for the whole app.
///
/// Rules enforced here:
/// * exactly one [AudioPlayer] exists for the app's lifetime — UI widgets never
///   build their own players;
/// * the whole queue lives inside ONE [ConcatenatingAudioSource], so
///   `just_audio` owns the current index and the notification / lock-screen
///   metadata can never drift away from what is actually audible;
/// * nothing here stops audio on lifecycle changes, widget disposal or
///   in-app navigation. Only an explicit [stop] does.
/// * every load is bounded by [connectTimeout] / [stallTimeout] so a dead
///   stream host produces a visible error + Retry instead of an eternal spinner.
class ZionAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  ZionAudioHandler({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  /// How long a stream/file gets to become playable before we report failure.
  static const Duration connectTimeout = Duration(seconds: 18);

  /// How long a stalled buffer is tolerated.
  static const Duration stallTimeout = Duration(seconds: 25);

  final AudioPlayer _player;

  final BehaviorSubject<String?> _error = BehaviorSubject<String?>.seeded(null);
  final BehaviorSubject<bool> _sessionReady =
      BehaviorSubject<bool>.seeded(false);

  List<MediaItem> _items = const <MediaItem>[];
  int _index = 0;
  bool _live = false;
  bool _disposed = false;
  double _volumeBeforeDuck = 1.0;

  Timer? _connectWatchdog;
  Timer? _stallWatchdog;
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  /// Last human-readable playback failure (Swahili), null while healthy.
  Stream<String?> get errorStream => _error.stream;
  String? get errorMessage => _error.valueOrNull;
  bool get hasError => _error.valueOrNull != null;
  Stream<bool> get sessionReadyStream => _sessionReady.stream;

  /// True once the handler is registered with `audio_service`, i.e. the OS media
  /// session (notification + lock screen) is live.
  bool backgroundActive = false;

  AudioPlayer get player => _player;
  List<MediaItem> get items => _items;
  int get currentIndex => _index;
  bool get isLive => _live;
  bool get isPlaying => _player.playing;
  bool get isBuffering =>
      _player.processingState == ProcessingState.buffering ||
      _player.processingState == ProcessingState.loading;
  Duration get position => _player.position;

  /// Live playback position. The UI ticks off this stream instead of owning a
  /// player of its own.
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration? get duration => _live ? null : _player.duration;
  double get volume => _player.volume;

  /// Configures the OS audio session and mirrors `just_audio` into the
  /// `audio_service` state streams.
  ///
  /// Web-safe: `audio_session` has no browser implementation, so a failure there
  /// is swallowed and playback still works inside the tab.
  Future<void> boot() async {
    _wireUp();
    await _configureAudioSession();
  }

  void _wireUp() {
    _subscriptions.add(_player.playbackEventStream.listen(
      (event) => playbackState.add(_transformEvent(event)),
      onError: (Object error, StackTrace _) =>
          _fail(_describe(error, _titleOfCurrent())),
    ));

    _subscriptions.add(_player.currentIndexStream.listen((index) {
      if (index == null || index < 0 || index >= _items.length) return;
      _index = index;
      _live = _isLiveItem(_items[index]);
      // Single source of truth for mini-player + notification + lock screen.
      mediaItem.add(_items[index]);
    }));

    _subscriptions.add(_player.processingStateStream.listen((state) {
      if (state == ProcessingState.ready ||
          state == ProcessingState.completed) {
        _cancelConnectWatchdog();
        _cancelStallWatchdog();
      } else if (state == ProcessingState.buffering ||
          state == ProcessingState.loading) {
        _armStallWatchdog();
      }
    }));

    // Fill in the real duration for on-demand content as soon as it is known.
    _subscriptions.add(_player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current == null || _live || duration == null) return;
      if (duration == current.duration) return;
      mediaItem.add(current.copyWith(duration: duration));
    }));
  }

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      // Music playback: keeps playing while locked, ducks for calls, pauses for
      // navigation prompts, and yields focus politely to other apps.
      await session.configure(const AudioSessionConfiguration.music());

      _subscriptions.add(session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (event.type == AudioInterruptionType.duck) {
            _volumeBeforeDuck = _player.volume;
            unawaited(
                _player.setVolume((_player.volume * 0.25).clamp(0.0, 1.0)));
          } else if (_player.playing) {
            unawaited(_player.pause());
          }
        } else if (_volumeBeforeDuck > _player.volume) {
          unawaited(_player.setVolume(_volumeBeforeDuck));
        }
      }));

      // Headphones unplugged / Bluetooth dropped -> pause like every other
      // music app, instead of blasting audio out of the speaker.
      _subscriptions.add(session.becomingNoisyEventStream.listen((_) {
        if (_player.playing) unawaited(_player.pause());
      }));

      _sessionReady.add(true);
    } catch (e) {
      debugPrint('Audio session unavailable (web?): $e');
      _sessionReady.add(false);
    }
  }

  // ---------------------------------------------------------------- playback

  /// Replaces the queue and starts playing [startIndex].
  ///
  /// This is the ONLY place audio gets loaded, so every screen, the mini-player
  /// and the media notification always agree.
  Future<void> playQueue(List<MediaItem> newQueue, int startIndex) async {
    if (newQueue.isEmpty) return;
    final items = List<MediaItem>.unmodifiable(newQueue);
    final index = startIndex.clamp(0, items.length - 1);
    final target = items[index];

    _items = items;
    _index = index;
    _live = _isLiveItem(target);
    _error.add(null);
    queue.add(items);
    mediaItem.add(target);

    final source = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: <AudioSource>[
        for (final item in items) AudioSource.uri(Uri.parse(item.id)),
      ],
    );

    _armConnectWatchdog(target.title);
    try {
      await _player
          .setAudioSource(source, initialIndex: index, preload: !_live)
          .timeout(connectTimeout);
    } on TimeoutException {
      await _abortLoad(target.title,
          'Mtiririko wa "${_shorten(target.title)}" haujafika. Angalia mtandao kisha ujaribu tena.');
      return;
    } catch (e) {
      await _abortLoad(target.title, _describe(e, target.title));
      return;
    }
    _cancelConnectWatchdog();

    if (_live) {
      // A live stream has no length: make sure no seek bar can be rendered.
      mediaItem.add(target.copyWith(duration: null));
    }
    await _startPlaying();
  }

  /// Back-compat entry point: plays one item as a queue of one.
  Future<void> playMediaItemSingle(MediaItem item) =>
      playQueue(<MediaItem>[item], 0);

  Future<void> _startPlaying() async {
    try {
      // Never awaited to completion: `play()` only resolves when playback ends.
      unawaited(_player.play().catchError((Object e) {
        _fail(_describe(e, _titleOfCurrent()));
      }));
    } catch (e) {
      _fail(_describe(e, _titleOfCurrent()));
    }
  }

  Future<void> _abortLoad(String title, String message) async {
    _cancelConnectWatchdog();
    _cancelStallWatchdog();
    try {
      await _player.stop();
    } catch (_) {
      // The platform player may already be dead; the error state is what matters.
    }
    _fail(message);
  }

  Future<void> jumpToIndex(int index) async {
    if (_items.isEmpty) return;
    final target = index.clamp(0, _items.length - 1);
    _error.add(null);
    _armConnectWatchdog(_items[target].title);
    try {
      await _player.seek(null, index: target).timeout(connectTimeout);
      if (!_player.playing) await _startPlaying();
    } on TimeoutException {
      await _abortLoad(_items[target].title,
          'Kubadilisha kwenda "${_shorten(_items[target].title)}" kuchukua muda mrefu.');
    } catch (_) {
      // Some platforms reject index seeks: reload the queue at that position.
      await playQueue(_items, target);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (_items.isEmpty) return;
    // Radio catalogues loop instead of dying on the last station.
    await jumpToIndex(_index + 1 >= _items.length ? 0 : _index + 1);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_items.isEmpty) return;
    await jumpToIndex(_index - 1 < 0 ? _items.length - 1 : _index - 1);
  }

  @override
  Future<void> skipToQueueItem(int index) => jumpToIndex(index);

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    if (newQueue.isEmpty) return;
    final currentIds = _items.map((m) => m.id).toSet();
    final newIds = newQueue.map((m) => m.id).toSet();
    if (currentIds.length == newIds.length && newIds.containsAll(currentIds)) {
      // Same material, maybe richer metadata: never reload the player for that.
      _items = List<MediaItem>.unmodifiable(newQueue);
      queue.add(_items);
      final current = mediaItem.value;
      if (current != null) {
        final match = newQueue.where((m) => m.id == current.id).firstOrNull;
        if (match != null) mediaItem.add(match);
      }
      return;
    }
    await playQueue(newQueue, 0);
  }

  @override
  Future<void> play() => _startPlaying();

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    final index = _items.indexWhere((m) => m.id == mediaId);
    if (index >= 0) {
      await jumpToIndex(index);
    } else if (extras != null && extras['url'] is String) {
      await playQueue(
          <MediaItem>[MediaItem(id: extras['url'] as String, title: mediaId)],
          0);
    } else {
      await _startPlaying();
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    _cancelConnectWatchdog();
    _cancelStallWatchdog();
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    if (_live) return; // Live radio never exposes a seek bar.
    _armStallWatchdog();
    await _player.seek(position);
  }

  Future<void> setVolume(double value) =>
      _player.setVolume(value.clamp(0.0, 1.0));

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// Retries the failed item without resetting the queue.
  Future<void> retryCurrent() async {
    if (_items.isEmpty) return;
    await playQueue(_items, _index);
  }

  Future<void> clearError() async => _error.add(null);

  // ------------------------------------------------------------------- state

  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = _player.playing;
    final processingState = switch (event.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    final hasQueue = _items.length > 1;
    final controls = <MediaControl>[
      if (hasQueue) MediaControl.skipToPrevious,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.stop,
      if (hasQueue) MediaControl.skipToNext,
    ];

    return PlaybackState(
      controls: controls,
      // Live radio must not offer a seek bar in the notification / lock screen.
      systemActions: _live
          ? const <MediaAction>{}
          : const <MediaAction>{
              MediaAction.seek,
              MediaAction.seekForward,
              MediaAction.seekBackward,
            },
      androidCompactActionIndices:
          hasQueue ? const <int>[0, 1, 3] : const <int>[0, 1],
      processingState: processingState,
      playing: playing,
      speed: _player.speed,
      bufferedPosition: _player.bufferedPosition,
      updatePosition: event.updatePosition,
      updateTime: event.updateTime,
      errorMessage: _error.valueOrNull,
      queueIndex: event.currentIndex ?? _index,
    );
  }

  String _titleOfCurrent() => _items.isEmpty
      ? 'Sauti'
      : (_items.length > _index ? _items[_index].title : 'Sauti');

  bool _isLiveItem(MediaItem item) {
    final extras = item.extras;
    if (extras == null) return false;
    if (extras['isLive'] == true) return true;
    return extras['mediaType'] == MediaType.radio.name;
  }

  String _describe(Object error, String title) {
    final text = error.toString();
    final name = _shorten(title);
    if (text.contains('Failed host lookup') ||
        text.contains('SocketException')) {
      return 'Muunganiko na "$name" haujafanyika — seva haipatikani.';
    }
    if (text.contains('TimeoutException')) {
      return '"$name" haitaki kuanza. Angalia mtandao wako kisha ujaribu tena.';
    }
    if (text.contains('HttpException') || text.contains('OS Error')) {
      return '"$name" imekata muunganiko. Bonyeza Jaribu Tena.';
    }
    if (text.contains('Unauthorized') || text.contains('Forbidden')) {
      return 'Redio hii imekataa msaada ($name). Chagua kituo kingine.';
    }
    return '"$name" imeshindwa kucheza. Bonyeza Jaribu Tena.';
  }

  static String _shorten(String value) {
    final clean = value.replaceAll('\n', ' ').trim();
    return clean.length <= 30 ? clean : '${clean.substring(0, 29)}…';
  }

  void _fail(String message) {
    if (_disposed) return;
    _cancelConnectWatchdog();
    _cancelStallWatchdog();
    _error.add(message);
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.error,
      controls: <MediaControl>[MediaControl.play],
      systemActions: const <MediaAction>{},
      playing: false,
      errorMessage: message,
    ));
  }

  void _armConnectWatchdog(String title) {
    _connectWatchdog?.cancel();
    _connectWatchdog = Timer(connectTimeout + const Duration(seconds: 5), () {
      final state = _player.processingState;
      if (state == ProcessingState.loading ||
          state == ProcessingState.buffering) {
        unawaited(_abortLoad(title,
            '"${_shorten(title)}" inachukua muda mrefu kuanza. Jaribu tena au chagua kituo kingine.'));
      }
    });
  }

  void _armStallWatchdog() {
    _stallWatchdog?.cancel();
    final mark = _player.bufferedPosition;
    _stallWatchdog = Timer(stallTimeout, () {
      final state = _player.processingState;
      if ((state == ProcessingState.buffering ||
              state == ProcessingState.loading) &&
          _player.bufferedPosition == mark) {
        unawaited(_abortLoad(_titleOfCurrent(),
            'Mtiririko umekwama. Bonyeza Jaribu Tena ili uendelee.'));
      }
    });
  }

  void _cancelConnectWatchdog() {
    _connectWatchdog?.cancel();
    _connectWatchdog = null;
  }

  void _cancelStallWatchdog() {
    _stallWatchdog?.cancel();
    _stallWatchdog = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    _cancelConnectWatchdog();
    _cancelStallWatchdog();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _player.dispose();
    await _error.close();
    await _sessionReady.close();
  }
}
