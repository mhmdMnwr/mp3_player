import 'package:flutter/material.dart';
import 'package:mp3_player_v2/core/logic/player_cubit.dart';
import 'package:mp3_player_v2/core/logic/player_state.dart';
import 'package:mp3_player_v2/features/all_audio/presentation/widgets/all_audio_header.dart';
import 'package:mp3_player_v2/features/all_audio/presentation/widgets/all_audio_list.dart';

class AllAudioPage extends StatelessWidget {
  final PlayerState playerState;
  final PlayerCubit playerCubit;
  final VoidCallback? onSongPlayed;

  const AllAudioPage({
    super.key,
    required this.playerState,
    required this.playerCubit,
    this.onSongPlayed,
  });

  Future<void> _scanDeviceAudio(PlayerCubit playerCubit) async {
    await playerCubit.scanAndLoadSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AllAudioHeader(onAddSong: () => _scanDeviceAudio(playerCubit)),
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
