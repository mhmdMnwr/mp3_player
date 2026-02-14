import 'package:flutter/material.dart';
import 'package:mp3_player_v2/core/theme/app_colors.dart';

class AllAudioHeader extends StatelessWidget {
  final VoidCallback onAddSong;

  const AllAudioHeader({super.key, required this.onAddSong});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ElevatedButton(
      onPressed: onAddSong,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.surface,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text('Add Audio'),
    );
  }
}
