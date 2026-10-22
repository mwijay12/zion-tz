import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';
import 'radio_browser_service.dart';

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

  MediaItem toMediaItem() {
    return MediaItem(
      id: audioUrl,
      album: subtitle,
      title: title,
      artUri: imageUrl != null ? Uri.parse(imageUrl!) : null,
      extras: {'trackId': id, 'isLiveRadio': isLiveRadio},
    );
  }
}

class ChurchAudioService extends ChangeNotifier {
  static final ChurchAudioService _instance = ChurchAudioService._internal();
  factory ChurchAudioService() => _instance;

  static late ZionAudioHandler _audioHandler;

  ChurchAudioService._internal();

  static Future<void> init() async {
    _audioHandler = await AudioService.init(
      builder: () => ZionAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.zion.church.audio',
        androidNotificationChannelName: 'Zion Audio Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_notification',
        androidStopForegroundOnPause: true,
      ),
    );
  }

  CurrentMediaTrack? _currentTrack;
  List<CurrentMediaTrack> _queue = [];
  int _queueIndex = 0;

  CurrentMediaTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _audioHandler.playbackState.value.playing;
  bool get isLoading => _audioHandler.playbackState.value.processingState == AudioProcessingState.loading || 
                        _audioHandler.playbackState.value.processingState == AudioProcessingState.buffering;
  Duration get position => _audioHandler.playbackState.value.updatePosition;
  Duration get duration => _audioHandler.mediaItem.value?.duration ?? Duration.zero;
  bool get hasActiveTrack => _currentTrack != null;
  bool get hasNext => _queue.isNotEmpty && _queueIndex < _queue.length - 1;
  bool get hasPrevious => _queue.isNotEmpty && _queueIndex > 0;

  static const List<GospelRadioStation> gospelRadios = [
    GospelRadioStation(
      id: 'praiseworld-ng',
      name: 'Praiseworld Radio',
      location: 'Lagos, Nigeria',
      streamUrl: 'https://streaming.radio.co/s7dc18f0ad/listen',
      tag: 'Afro Gospel, Praise & Worship 24/7',
      iconEmoji: '🇳🇬',
    ),
    GospelRadioStation(
      id: 'ng-gospel-live',
      name: 'Nigerian Gospel Music Radio',
      location: 'Lagos, Nigeria',
      streamUrl: 'http://stream.zeno.fm/3fmqr74a7f8uv',
      tag: 'Gospel Praise & Worship',
      iconEmoji: '🇳🇬',
    ),
    GospelRadioStation(
      id: 'gospotainment-live',
      name: 'Gospotainment Radio',
      location: 'West Africa',
      streamUrl: 'https://radio.gotright.net/radio/8000/radio.mp3',
      tag: 'Afrobeats Gospel Hits',
      iconEmoji: '🔥',
    ),
    GospelRadioStation(
      id: 'wigradio-live',
      name: 'WiGRadio Live',
      location: 'Africa & Global',
      streamUrl: 'https://stream.zeno.fm/w74w7e91sm8uv',
      tag: 'Christian Talk, Worship & Injili',
      iconEmoji: '🕊️',
    ),
    GospelRadioStation(
      id: 'praise-live-global',
      name: 'Praise Live Radio',
      location: 'Global Christian Network',
      streamUrl: 'https://stream.streamexperts.com:8062/live',
      tag: 'Live Contemporary Worship',
      iconEmoji: '🌍',
    ),
  ];

  void setQueue(List<CurrentMediaTrack> tracks, {int startIndex = 0}) {
    _queue = List.from(tracks);
    _queueIndex = (startIndex >= 0 && startIndex < tracks.length) ? startIndex : 0;
    
    final mediaItems = tracks.map((t) => t.toMediaItem()).toList();
    _audioHandler.updateQueue(mediaItems);
    
    if (_queue.isNotEmpty) {
      playTrackItem(_queue[_queueIndex]);
    }
  }

  Future<void> playTrackItem(CurrentMediaTrack track) async {
    _currentTrack = track;
    notifyListeners();
    await _audioHandler.playMediaItem(track.toMediaItem());
  }

  Future<void> playTrack({
    required String id,
    required String title,
    required String subtitle,
    required String audioUrl,
    String? imageUrl,
    bool isLiveRadio = false,
  }) async {
    final track = CurrentMediaTrack(
      id: id,
      title: title,
      subtitle: subtitle,
      audioUrl: audioUrl,
      imageUrl: imageUrl ?? 'https://sc02.alicdn.com/kf/A4bfa57aaae7e48a0ab6ac33942d9da1et.png',
      isLiveRadio: isLiveRadio,
    );
    await playTrackItem(track);
  }

  Future<void> playNext() async {
    if (hasNext) {
      _queueIndex++;
      await playTrackItem(_queue[_queueIndex]);
    }
  }

  Future<void> playPrevious() async {
    if (hasPrevious) {
      _queueIndex--;
      await playTrackItem(_queue[_queueIndex]);
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
    notifyListeners();
  }

  Future<void> seek(Duration newPosition) async {
    await _audioHandler.seek(newPosition);
  }

  Future<void> playRadioStation(GospelRadioStation station) async {
    await playTrack(
      id: station.id,
      title: station.name,
      subtitle: station.tag,
      audioUrl: station.streamUrl,
      isLiveRadio: true,
    );
  }

  Future<void> playRadioBrowserStation(RadioStation station) async {
    await playTrack(
      id: station.stationuuid,
      title: station.name,
      subtitle: station.displaySubtitle,
      audioUrl: station.urlResolved,
      isLiveRadio: true,
    );
  }

  Future<void> stop() async {
    await _audioHandler.stop();
    _currentTrack = null;
    notifyListeners();
  }
}
