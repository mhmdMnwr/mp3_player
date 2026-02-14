import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:mp3_player_v2/core/data/model/audio_model.dart';
import 'package:mp3_player_v2/core/logic/player_cubit.dart';
import 'package:mp3_player_v2/core/logic/player_state.dart';
import 'package:mp3_player_v2/features/all_audio/presentation/widgets/all_audio_header.dart';
import 'package:mp3_player_v2/features/all_audio/presentation/widgets/all_audio_list.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AllAudioPage extends StatelessWidget {
  static const String _defaultArtwork = 'assets/images/podcast.png';
  final PlayerState playerState;
  final PlayerCubit playerCubit;
  final VoidCallback? onSongPlayed;

  const AllAudioPage({
    super.key,
    required this.playerState,
    required this.playerCubit,
    this.onSongPlayed,
  });

  Future<void> _addSong(PlayerCubit playerCubit) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final audios = <AudioModel>[];

    for (final file in result.files) {
      final filePath = file.path;
      if (filePath == null || filePath.isEmpty) {
        continue;
      }

      final title = p.basenameWithoutExtension(filePath).trim();
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      final artworkPath = await _extractArtworkPath(
        audioFilePath: filePath,
        audioId: id,
      );

      audios.add(
        AudioModel(
          id: id,
          title: title.isEmpty ? 'Unknown Title' : title,
          artist: 'Unknown Artist',
          imagePath: artworkPath,
          duration: '--:--',
          filePath: filePath,
        ),
      );
    }

    if (audios.isEmpty) {
      return;
    }

    await playerCubit.storeAudiosFromLocalFiles(audios);
  }

  Future<String> _extractArtworkPath({
    required String audioFilePath,
    required String audioId,
  }) async {
    try {
      final metadata = await MetadataRetriever.fromFile(File(audioFilePath));
      final albumArt = metadata.albumArt;

      if (albumArt == null || albumArt.isEmpty) {
        return _defaultArtwork;
      }

      final dir = await getApplicationDocumentsDirectory();
      final artworkDir = Directory(p.join(dir.path, 'artworks'));
      if (!await artworkDir.exists()) {
        await artworkDir.create(recursive: true);
      }

      final artworkPath = p.join(artworkDir.path, 'artwork_$audioId.jpg');
      final artworkFile = File(artworkPath);
      await artworkFile.writeAsBytes(albumArt, flush: true);

      return artworkPath;
    } catch (_) {
      return _defaultArtwork;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AllAudioHeader(onAddSong: () => _addSong(playerCubit)),
        const SizedBox(height: 16),
        Expanded(
          child: AllAudioList(
            state: playerState,
            onSongTap: (song) async {
              await playerCubit.selectSongById(song.id, autoPlay: true);
              onSongPlayed?.call();
            },
          ),
        ),
      ],
    );
  }
}
