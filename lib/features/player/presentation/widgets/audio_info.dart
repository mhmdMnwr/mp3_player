import 'package:flutter/material.dart';
import 'package:mp3_player_v2/core/theme/app_colors.dart';

class AudioInfo extends StatefulWidget {
  final String? title;
  final String? artist;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onFavoriteLongPress;
  const AudioInfo({
    super.key,
    this.title,
    this.artist,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.onFavoriteLongPress,
  });

  @override
  State<AudioInfo> createState() => _AudioInfoState();
}

class _AudioInfoState extends State<AudioInfo> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(covariant AudioInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildTitleArtist(widget.title, widget.artist)),
        const SizedBox(width: 12),
        _buildFavoriteIcon(_isFavorite),
      ],
    );
  }

  Widget _buildTitleArtist(String? title, String? artist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? 'Unknown Title',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          artist ?? 'Unknown Artist',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFavoriteIcon(bool isFavorite) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        widget.onFavoriteTap?.call();
      },
      onLongPress: widget.onFavoriteLongPress,
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: const Size(44, 40),
        backgroundColor: isFavorite ? AppColors.error : AppColors.surface,
        foregroundColor: isFavorite ? AppColors.surface : AppColors.error,
        side: const BorderSide(color: AppColors.error, width: 1.4),
        elevation: isFavorite ? 6 : 0,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.26),
      ),
      child: Row(
        children: [
          Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          if (isFavorite) ...[const SizedBox(width: 6), const Text('Favorite')],
        ],
      ),
    );
  }
}
