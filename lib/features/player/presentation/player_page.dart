import 'package:flutter/material.dart';
import 'package:mp3_player_v2/core/logic/player_cubit.dart';
import 'package:mp3_player_v2/core/logic/player_state.dart';
import 'package:mp3_player_v2/features/player/presentation/widgets/audio_image.dart';
import 'package:mp3_player_v2/features/player/presentation/widgets/audio_info.dart';
import 'package:mp3_player_v2/features/player/presentation/widgets/audio_play_buttons.dart';
import 'package:mp3_player_v2/features/player/presentation/widgets/audio_slider.dart';

class PlayerPage extends StatelessWidget {
  final PlayerState playerState;
  final PlayerCubit playerCubit;
  final VoidCallback? onFavoriteLongPress;

  const PlayerPage({
    super.key,
    required this.playerState,
    required this.playerCubit,
    this.onFavoriteLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Center(
            child: AudioImage(imagePath: playerState.currentSong?.imagePath),
          ),
          const SizedBox(height: 70),
          AudioInfo(
            title: playerState.currentSong?.title ?? 'Unknown Title',
            artist: playerState.currentSong?.artist ?? 'Unknown Artist',
            isFavorite: playerState.currentSong?.isFavorite ?? false,
            onFavoriteTap: playerCubit.toggleCurrentSongFavorite,
            onFavoriteLongPress: onFavoriteLongPress,
          ),
          const SizedBox(height: 16),
          AudioSlider(
            duration: playerState.duration,
            position: playerState.position,
            onChanged: playerCubit.seek,
          ),
          const SizedBox(height: 20),
          AudioPlayButtons(
            isPlaying: playerState.isPlaying,
            onPrevious: playerCubit.previous,
            onNext: playerCubit.next,
            onPlayPauseChanged: (isPlaying) {
              if (isPlaying) {
                playerCubit.play();
              } else {
                playerCubit.pause();
              }
            },
          ),
        ],
      ),
    );
  }
}
