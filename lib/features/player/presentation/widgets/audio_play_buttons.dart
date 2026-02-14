import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mp3_player_v2/core/logic/player_cubit.dart';
import 'package:mp3_player_v2/core/theme/app_colors.dart';

class AudioPlayButtons extends StatefulWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;
  final ValueChanged<bool>? onPlayPauseChanged;
  final bool isPlaying;

  const AudioPlayButtons({
    super.key,
    this.onPrevious,
    this.onNext,
    this.onShuffle,
    this.onRepeat,
    this.onPlayPauseChanged,
    this.isPlaying = false,
  });

  @override
  State<AudioPlayButtons> createState() => _AudioPlayButtonsState();
}

class _AudioPlayButtonsState extends State<AudioPlayButtons>
    with TickerProviderStateMixin {
  bool _hasStarted = false;
  bool _isPlaying = false;
  late final AnimationController _revealController;
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
    _hasStarted = widget.isPlaying;

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (_hasStarted) {
      _revealController.value = 1;
    }

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant AudioPlayButtons oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isPlaying != widget.isPlaying) {
      _isPlaying = widget.isPlaying;

      if (widget.isPlaying && !_hasStarted) {
        _hasStarted = true;
        _revealController.forward();
      }
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onMainPressed() {
    _pressController
      ..stop()
      ..forward(from: 0).then((_) {
        if (mounted) {
          _pressController.reverse();
        }
      });

    setState(() {
      if (!_hasStarted) {
        _hasStarted = true;
        _isPlaying = true;
        _revealController.forward();
      } else {
        _isPlaying = !_isPlaying;
      }
    });

    widget.onPlayPauseChanged?.call(_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final nearOffset = (width * 0.25).clamp(74.0, 104.0).toDouble();
        final farOffset = (width * 0.45).clamp(122.0, 150.0).toDouble();

        return SizedBox(
          height: 86,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildAnimatedSideButton(
                icon: context.read<PlayerCubit>().isShuffleMode
                    ? Icons.shuffle_on_outlined
                    : Icons.shuffle,

                onPressed: widget.onShuffle,
                iconSize: 40,
                targetOffsetX: -farOffset,
                curve: const Interval(0.0, 0.9, curve: Curves.easeOutBack),
              ),
              _buildAnimatedSideButton(
                icon: Icons.skip_previous_rounded,
                onPressed: widget.onPrevious,
                iconSize: 38,
                targetOffsetX: -nearOffset,
                curve: const Interval(0.1, 1.0, curve: Curves.easeOutBack),
              ),
              _buildMainButton(),
              _buildAnimatedSideButton(
                icon: Icons.skip_next_rounded,
                onPressed: widget.onNext,
                iconSize: 38,
                targetOffsetX: nearOffset,
                curve: const Interval(0.1, 1.0, curve: Curves.easeOutBack),
              ),
              _buildAnimatedSideButton(
                icon: Icons.repeat,
                onPressed: widget.onRepeat,
                iconSize: 40,
                targetOffsetX: farOffset,
                curve: const Interval(0.0, 0.9, curve: Curves.easeOutBack),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainButton() {
    final colors = context.colors;
    return ScaleTransition(
      scale: _pressScale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (_isPlaying)
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.26),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: SizedBox(
          width: 75,
          height: 75,
          child: ElevatedButton(
            onPressed: _onMainPressed,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: colors.surface,
              foregroundColor: colors.textPrimary,
              elevation: 0,
              side: BorderSide(color: colors.textPrimary, width: 3),
              padding: EdgeInsets.zero,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey<bool>(_isPlaying),
                size: 42,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required VoidCallback? onPressed,
    double iconSize = 28,
  }) {
    final colors = context.colors;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      color: colors.textPrimary,
    );
  }

  Widget _buildAnimatedSideButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required double targetOffsetX,
    required Curve curve,
    double iconSize = 28,
  }) {
    final progress = CurvedAnimation(parent: _revealController, curve: curve);

    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final opacityValue = progress.value.clamp(0.0, 1.0);
        final scaleValue = 0.7 + (opacityValue * 0.3);
        final rotationValue =
            (1 - opacityValue) * (targetOffsetX.isNegative ? -0.35 : 0.35);
        final liftValue = (1 - opacityValue) * 10;

        return Transform.translate(
          offset: Offset(targetOffsetX * progress.value, -liftValue),
          child: Transform.rotate(
            angle: rotationValue,
            child: Transform.scale(
              scale: scaleValue,
              child: Opacity(opacity: opacityValue, child: child),
            ),
          ),
        );
      },
      child: IgnorePointer(
        ignoring: !_hasStarted,
        child: _buildSideButton(
          icon: icon,
          onPressed: onPressed,
          iconSize: iconSize,
        ),
      ),
    );
  }
}
