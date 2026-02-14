import 'package:mp3_player_v2/core/data/model/audio_model.dart';

enum PlayerStatus { initial, loading, loaded, error }

class PlayerState {
  final PlayerStatus status;
  final List<AudioModel> songs;
  final List<AudioModel> favoriteSongs;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  const PlayerState({
    this.status = PlayerStatus.initial,
    this.songs = const [],
    this.favoriteSongs = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  AudioModel? get currentSong {
    if (songs.isEmpty || currentIndex < 0 || currentIndex >= songs.length) {
      return null;
    }
    return songs[currentIndex];
  }

  bool get hasSongs => songs.isNotEmpty;

  PlayerState copyWith({
    PlayerStatus? status,
    List<AudioModel>? songs,
    List<AudioModel>? favoriteSongs,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PlayerState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      favoriteSongs: favoriteSongs ?? this.favoriteSongs,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
