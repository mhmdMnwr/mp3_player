import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:mp3_player_v2/core/data/model/audio_model.dart';
import 'package:mp3_player_v2/core/data/repo/audio_repo.dart';
import 'package:mp3_player_v2/core/logic/player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  static PlayerCubit? _instance;

  factory PlayerCubit({required AudioRepo audioRepo}) {
    _instance ??= PlayerCubit._internal(audioRepo: audioRepo);
    return _instance!;
  }

  final AudioRepo _audioRepo;
  final ja.AudioPlayer _audioPlayer = ja.AudioPlayer();
  StreamSubscription<ja.PlayerState>? _audioPlayerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  int? _loadedSongIndex;

  PlayerCubit._internal({required AudioRepo audioRepo})
    : _audioRepo = audioRepo,
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
  }

  Future<void> loadSongs({
    String? selectedSongId,
    bool autoPlay = false,
  }) async {
    emit(state.copyWith(status: PlayerStatus.loading, clearErrorMessage: true));

    try {
      final songs = await _audioRepo.getAllSongs();
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

  Future<void> storeAudiosFromLocalFiles(List<AudioModel> audios) async {
    try {
      await _audioRepo.storeAudiosFromLocalFiles(audios);
      await loadSongs();
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

  Future<void> loadFavoriteSongs() async {
    emit(state.copyWith(status: PlayerStatus.loading, clearErrorMessage: true));

    try {
      final favoriteSongs = await _audioRepo.getFavoriteSongs();
      emit(
        state.copyWith(
          status: PlayerStatus.loaded,
          favoriteSongs: favoriteSongs,
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
      await _audioRepo.setSongFavorite(
        songId: currentSong.id,
        isFavorite: newFavoriteValue,
      );

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

  Future<void> next() async {
    if (!state.hasSongs) {
      return;
    }

    final isLast = state.currentIndex >= state.songs.length - 1;
    final nextIndex = isLast ? 0 : state.currentIndex + 1;

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
  }

  Future<void> disposePlayer() async {
    await _audioPlayerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _audioPlayer.dispose();
    await super.close();
    _instance = null;
  }
}
