import 'package:flutter/material.dart';

class AudioSlider extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onChanged;

  const AudioSlider({
    super.key,
    required this.duration,
    required this.position,
    required this.onChanged,
  });

  @override
  State<AudioSlider> createState() => _AudioSliderState();
}

class _AudioSliderState extends State<AudioSlider> {
  late Duration _draggedPosition;

  @override
  void initState() {
    super.initState();
    _draggedPosition = widget.position;
  }

  @override
  void didUpdateWidget(AudioSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _draggedPosition = widget.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxSeconds = widget.duration.inSeconds > 0
        ? widget.duration.inSeconds.toDouble()
        : 1.0;
    final currentSeconds = _draggedPosition.inSeconds
        .toDouble()
        .clamp(0.0, maxSeconds)
        .toDouble();

    return Column(
      children: [
        Slider(
          min: 0,
          value: currentSeconds,
          max: maxSeconds,
          onChanged: (value) {
            setState(() {
              _draggedPosition = Duration(seconds: value.toInt());
            });
            widget.onChanged(_draggedPosition);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(_draggedPosition)),
            Text(_formatDuration(widget.duration)),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
