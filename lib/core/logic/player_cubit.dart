import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mp3_player_v2/core/data/repo/audio_repo.dart';
import 'package:mp3_player_v2/core/logic/audio_handler.dart';
import 'package:mp3_player_v2/core/logic/player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  static PlayerCubit? _instance;

  factory PlayerCubit({
    required AudioRepo audioRepo,
    required AppAudioHandler audioHandler,
  }) {
    _instance ??= PlayerCubit._internal(
      audioRepo: audioRepo,
      audioHandler: audioHandler,
    );
    return _instance!;
  }

  final AudioRepo _audioRepo;
  final AppAudioHandler _audioHandler;
  ja.AudioPlayer get _audioPlayer => _audioHandler.player;
  StreamSubscription<ja.PlayerState>? _audioPlayerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<dynamic>? _customEventSubscription;
  bool isShuffleMode = false;
  int? _loadedSongIndex;

  PlayerCubit._internal({
    required AudioRepo audioRepo,
    required AppAudioHandler audioHandler,
  }) : _audioRepo = audioRepo,
       _audioHandler = audioHandler,
       super(const PlayerState()) {
    _audioPlayerStateSubscription = _audioPlayer.playerStateStream.listen((
      playerState,
    ) {
      if (playerState.processingState == ja.ProcessingState.completed) {
        next();
        return;
      }

      if (state.isPlaying != playerState.playing) {
        emit(state.copyWith(isPlaying: playerState.playing));
      }
    });

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      emit(state.copyWith(position: position));
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      emit(state.copyWith(duration: duration ?? Duration.zero));
    });

    // Listen for next/prev from notification bar
    _customEventSubscription = _audioHandler.customEvent.listen((event) {
      if (event == 'skipToNext') {
        next();
      } else if (event == 'skipToPrevious') {
        previous();
      }
    });
  }

  Future<void> loadSongs({
    String? selectedSongId,
    bool autoPlay = false,
  }) async {
    emit(state.copyWith(status: PlayerStatus.loading, clearErrorMessage: true));

    try {
      final songs = await _audioRepo.scanDeviceSongs();
      int selectedIndex = 0;

      if (selectedSongId != null) {
        final index = songs.indexWhere((song) => song.id == selectedSongId);
        if (index != -1) {
          selectedIndex = index;
        }
      }

      emit(
        state.copyWith(
          status: PlayerStatus.loaded,
          songs: songs,
          favoriteSongs: songs.where((song) => song.isFavorite).toList(),
          currentIndex: songs.isEmpty ? 0 : selectedIndex,
          isPlaying: false,
          position: Duration.zero,
          duration: Duration.zero,
          clearErrorMessage: true,
        ),
      );

      _loadedSongIndex = null;

      if (songs.isNotEmpty) {
        await _setCurrentSongSource();
      }

      if (autoPlay) {
        await play();
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PlayerStatus.error,
          errorMessage: e.toString(),
          isPlaying: false,
        ),
      );
    }
  }

  /// Scan device for MP3s and reload the song list.
  Future<void> scanAndLoadSongs() async {
    await loadSongs();
  }

  Future<void> loadFavoriteSongs() async {
    // Favorites are already in state.songs; just refresh from DB
    try {
      final favoriteIds = await _audioRepo.getFavoriteIds();
      final updatedSongs = state.songs
          .map(
            (song) => song.copyWith(isFavorite: favoriteIds.contains(song.id)),
          )
          .toList();

      emit(
        state.copyWith(
          songs: updatedSongs,
          favoriteSongs: updatedSongs.where((song) => song.isFavorite).toList(),
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: PlayerStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> toggleCurrentSongFavorite() async {
    final currentSong = state.currentSong;
    if (currentSong == null) {
      return;
    }

    final newFavoriteValue = !currentSong.isFavorite;

    try {
      await _audioRepo.setFavorite(currentSong.id, newFavoriteValue);

      final updatedSongs = state.songs
          .map(
            (song) => song.id == currentSong.id
                ? song.copyWith(isFavorite: newFavoriteValue)
                : song,
          )
          .toList();

      emit(
        state.copyWith(
          songs: updatedSongs,
          favoriteSongs: updatedSongs.where((song) => song.isFavorite).toList(),
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: PlayerStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> play() async {
    if (!state.hasSongs) {
      return;
    }

    try {
      await _setCurrentSongSource();
      await _audioPlayer.play();
      emit(state.copyWith(isPlaying: true));
    } catch (e) {
      emit(
        state.copyWith(
          status: PlayerStatus.error,
          errorMessage: e.toString(),
          isPlaying: false,
        ),
      );
    }
  }

  Future<void> pause() async {
    if (!state.hasSongs) {
      return;
    }

    await _audioPlayer.pause();
    emit(state.copyWith(isPlaying: false));
  }

  Future<void> seek(Duration position) async {
    if (!state.hasSongs) {
      return;
    }
    await _audioPlayer.seek(position);
  }

  Future<void> playPause() async {
    if (!state.hasSongs) {
      return;
    }

    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> selectSongById(String songId, {bool autoPlay = false}) async {
    if (!state.hasSongs) {
      return;
    }

    final index = state.songs.indexWhere((song) => song.id == songId);
    if (index == -1) {
      return;
    }

    emit(state.copyWith(currentIndex: index, isPlaying: autoPlay));

    _loadedSongIndex = null;
    await _setCurrentSongSource();
    await _audioPlayer.seek(Duration.zero);

    if (autoPlay) {
      await _audioPlayer.play();
    } else {
      await _audioPlayer.pause();
    }
  }

  Future<bool> toggleShuffle() async {
    isShuffleMode = !isShuffleMode;
    // For simplicity, we won't implement actual shuffling logic here.
    return isShuffleMode;
  }

  Future<void> next() async {
    if (!state.hasSongs) {
      return;
    }

    int next = isShuffleMode
        ? Random().nextInt(state.songs.length)
        : state.currentIndex + 1;

    final isLast = state.currentIndex >= state.songs.length - 1;
    final nextIndex = isLast ? 0 : next;

    emit(state.copyWith(currentIndex: nextIndex, isPlaying: true));

    _loadedSongIndex = null;
    await _setCurrentSongSource();
    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.play();
  }

  Future<void> previous() async {
    if (!state.hasSongs) {
      return;
    }

    final isFirst = state.currentIndex <= 0;
    final previousIndex = isFirst
        ? state.songs.length - 1
        : state.currentIndex - 1;

    emit(state.copyWith(currentIndex: previousIndex, isPlaying: true));

    _loadedSongIndex = null;
    await _setCurrentSongSource();
    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.play();
  }

  Future<void> _setCurrentSongSource() async {
    final currentSong = state.currentSong;
    if (currentSong == null) {
      return;
    }

    if (_loadedSongIndex == state.currentIndex) {
      return;
    }

    await _audioPlayer.setFilePath(currentSong.filePath);
    _loadedSongIndex = state.currentIndex;

    // Update notification with current song info
    await _audioHandler.setCurrentMedia(
      id: currentSong.id,
      title: currentSong.title,
      artist: currentSong.artist,
      duration: _audioPlayer.duration ?? Duration.zero,
    );
  }

  Future<void> disposePlayer() async {
    await _audioPlayerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _customEventSubscription?.cancel();
    await _audioHandler.stop();
    await _audioPlayer.dispose();
    await super.close();
    _instance = null;
  }
}
