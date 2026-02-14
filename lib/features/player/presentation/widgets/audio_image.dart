import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mp3_player_v2/core/theme/app_colors.dart';

class AudioImage extends StatefulWidget {
  final String? imagePath;
  const AudioImage({super.key, this.imagePath});

  @override
  State<AudioImage> createState() => _AudioImageState();
}

class _AudioImageState extends State<AudioImage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imagePath = widget.imagePath;
    final useAsset = imagePath == null || imagePath.startsWith('assets/');

    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.26),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: useAsset
            ? Image.asset(
                imagePath ?? 'assets/images/podcast.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _fallbackImage(context);
                },
              )
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _fallbackImage(context);
                },
              ),
      ),
    );
  }

  Widget _fallbackImage(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.card,
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note_rounded,
        size: 48,
        color: colors.iconInactive,
      ),
    );
  }
}
