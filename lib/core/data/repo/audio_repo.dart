import 'package:mp3_player_v2/core/data/model/audio_model.dart';
import 'package:mp3_player_v2/core/data/service/local_storage.dart';

abstract class AudioRepo {
  Future<void> storeAudiosFromLocalFiles(List<AudioModel> audios);
  Future<List<AudioModel>> getAllSongs();
  Future<List<AudioModel>> getFavoriteSongs();
  Future<void> setSongFavorite({
    required String songId,
    required bool isFavorite,
  });
}

class AudioRepoImpl implements AudioRepo {
  final LocalStorageService _localStorageService;

  AudioRepoImpl({LocalStorageService? localStorageService})
    : _localStorageService = localStorageService ?? LocalStorageService();

  @override
  Future<void> storeAudiosFromLocalFiles(List<AudioModel> audios) async {
    try {
      await _localStorageService.storeAudiosFromLocalFiles(audios);
    } catch (e) {
      throw Exception('Failed to store local audios: $e');
    }
  }

  @override
  Future<List<AudioModel>> getAllSongs() async {
    try {
      return await _localStorageService.getAllSongs();
    } catch (e) {
      throw Exception('Failed to get all songs: $e');
    }
  }

  @override
  Future<List<AudioModel>> getFavoriteSongs() async {
    try {
      return await _localStorageService.getFavoriteSongs();
    } catch (e) {
      throw Exception('Failed to get favorite songs: $e');
    }
  }

  @override
  Future<void> setSongFavorite({
    required String songId,
    required bool isFavorite,
  }) async {
    try {
      await _localStorageService.setSongFavorite(
        songId: songId,
        isFavorite: isFavorite,
      );
    } catch (e) {
      throw Exception('Failed to update favorite song: $e');
    }
  }
}
