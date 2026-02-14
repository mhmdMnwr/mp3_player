import 'package:flutter/material.dart';
import 'package:mp3_player_v2/core/theme/app_colors.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioImage extends StatefulWidget {
  final int? artworkId;
  const AudioImage({super.key, this.artworkId});

  @override
  State<AudioImage> createState() => _AudioImageState();
}

class _AudioImageState extends State<AudioImage> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
        child: widget.artworkId != null
            ? QueryArtworkWidget(
                id: widget.artworkId!,
                type: ArtworkType.AUDIO,
                artworkFit: BoxFit.cover,
                artworkWidth: MediaQuery.of(context).size.width * 0.8,
                artworkHeight: 260,
                keepOldArtwork: true,
                nullArtworkWidget: _fallbackImage(context),
              )
            : _fallbackImage(context),
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
