import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Bridges just_audio with the system media notification.
/// Handles play/pause/next/prev from the notification bar.
class AppAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  AppAudioHandler() {
    // Forward player state to audio_service so the notification updates.
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  /// Set the current media item (shown in the notification).
  Future<void> setCurrentMedia({
    required String id,
    required String title,
    required String artist,
    required Duration duration,
  }) async {
    final item = MediaItem(
      id: id,
      title: title,
      artist: artist,
      duration: duration,
    );
    mediaItem.add(item);
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
    return super.stop();
  }

  @override
  Future<void> skipToNext() async {
    // Handled by PlayerCubit — this just triggers the callback.
    // We add a custom action that PlayerCubit listens to.
    customEvent.add('skipToNext');
  }

  @override
  Future<void> skipToPrevious() async {
    customEvent.add('skipToPrevious');
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapProcessingState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}
