import 'package:flutter/material.dart';
import 'package:mp3_player_v2/core/logic/player_cubit.dart';
import 'package:mp3_player_v2/core/logic/player_state.dart';
import 'package:mp3_player_v2/features/all_audio/presentation/widgets/all_audio_list.dart';

class FavoritePage extends StatelessWidget {
  final PlayerState playerState;
  final PlayerCubit playerCubit;
  final VoidCallback? onSongPlayed;

  const FavoritePage({
    super.key,
    required this.playerState,
    required this.playerCubit,
    this.onSongPlayed,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteState = playerState.copyWith(
      songs: playerState.favoriteSongs,
    );

    return AllAudioList(
      state: favoriteState,
      onSongTap: (song) async {
        await playerCubit.selectSongById(song.id, autoPlay: true);
        onSongPlayed?.call();
      },
    );
  }
}
