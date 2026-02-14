import 'package:mp3_player_v2/core/data/model/audio_model.dart';
import 'package:mp3_player_v2/core/data/service/local_storage.dart';
import 'package:on_audio_query/on_audio_query.dart';

abstract class AudioRepo {
  Future<List<AudioModel>> scanDeviceSongs();
  Future<Set<String>> getFavoriteIds();
  Future<void> setFavorite(String songId, bool isFavorite);
}

class AudioRepoImpl implements AudioRepo {
  final LocalStorageService _localStorageService;
  final OnAudioQuery _audioQuery;

  AudioRepoImpl({
    LocalStorageService? localStorageService,
    OnAudioQuery? audioQuery,
  }) : _localStorageService = localStorageService ?? LocalStorageService(),
       _audioQuery = audioQuery ?? OnAudioQuery();

  @override
  Future<List<AudioModel>> scanDeviceSongs() async {
    // Request permission
    final hasPermission = await _audioQuery.permissionsStatus();
    if (!hasPermission) {
      final granted = await _audioQuery.permissionsRequest();
      if (!granted) {
        throw Exception('Storage permission denied');
      }
    }

    // Query all songs from MediaStore
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    // Get favorite IDs from local DB
    final favoriteIds = await _localStorageService.getFavoriteIds();

    return songs.where((song) => song.data.endsWith('.mp3')).map((song) {
      final durationMs = song.duration ?? 0;
      final minutes = (durationMs ~/ 60000).toString().padLeft(2, '0');
      final seconds = ((durationMs % 60000) ~/ 1000).toString().padLeft(2, '0');

      return AudioModel(
        id: song.id.toString(),
        title: song.title.isNotEmpty ? song.title : 'Unknown Title',
        artist: (song.artist != null && song.artist!.isNotEmpty)
            ? song.artist!
            : 'Unknown Artist',
        duration: '$minutes:$seconds',
        filePath: song.data, // real path from MediaStore, no copying
        artworkId: song.id,
        isFavorite: favoriteIds.contains(song.id.toString()),
      );
    }).toList();
  }

  @override
  Future<Set<String>> getFavoriteIds() async {
    return _localStorageService.getFavoriteIds();
  }

  @override
  Future<void> setFavorite(String songId, bool isFavorite) async {
    await _localStorageService.setFavorite(songId, isFavorite);
  }
}
