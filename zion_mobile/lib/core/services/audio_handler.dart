import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class ZionAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  ZionAudioHandler() {
    // Broadcast state changes from just_audio to audio_service
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen to changes in the current item
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });

    // Listen to completion and move to next
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> playMediaItem(MediaItem item) async {
    // Add Zion Mascot art if missing
    final enhancedItem = item.copyWith(
      artUri: item.artUri ?? Uri.parse('https://sc02.alicdn.com/kf/A4bfa57aaae7e48a0ab6ac33942d9da1et.png'),
    );
    mediaItem.add(enhancedItem);
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(enhancedItem.id)));
      _player.play();
    } catch (e) {
      print("Error playing media item: $e");
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    queue.add(newQueue);
    final audioSource = ConcatenatingAudioSource(
      children: newQueue
          .map((item) => AudioSource.uri(Uri.parse(item.id)))
          .toList(),
    );
    await _player.setAudioSource(audioSource);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
