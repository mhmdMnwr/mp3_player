import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mp3_player_v2/core/data/model/audio_model.dart';
import 'package:mp3_player_v2/core/logic/player_state.dart';
import 'package:mp3_player_v2/core/theme/app_colors.dart';

class AllAudioList extends StatelessWidget {
  final PlayerState state;
  final ValueChanged<AudioModel> onSongTap;

  const AllAudioList({super.key, required this.state, required this.onSongTap});

  @override
  Widget build(BuildContext context) {
    if (state.status == PlayerStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == PlayerStatus.error) {
      return Center(
        child: Text(
          state.errorMessage ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    if (state.songs.isEmpty) {
      return const Center(
        child: Text(
          'No audios yet. Tap Add Audio.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.songs.length,
      itemBuilder: (context, index) {
        final song = state.songs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            onTap: () => onSongTap(song),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildSongArtwork(song.imagePath),
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: Text(
              song.duration,
              style: const TextStyle(color: AppColors.textDisabled),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongArtwork(String imagePath) {
    final isAsset = imagePath.startsWith('assets/');

    if (isAsset) {
      return Image.asset(
        imagePath,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildArtworkFallback();
        },
      );
    }

    return Image.file(
      File(imagePath),
      width: 44,
      height: 44,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildArtworkFallback();
      },
    );
  }

  Widget _buildArtworkFallback() {
    return Container(
      width: 44,
      height: 44,
      color: AppColors.card,
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.iconInactive,
      ),
    );
  }
}
