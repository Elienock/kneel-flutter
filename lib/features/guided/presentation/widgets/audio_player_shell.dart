import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/features/guided/domain/entities/guided_session.dart';

/// Audio player shell widget (visual only, no playback).
/// This is a UI placeholder for future audio functionality.
class AudioPlayerShell extends StatefulWidget {
  final GuidedSession session;

  const AudioPlayerShell({
    super.key,
    required this.session,
  });

  @override
  State<AudioPlayerShell> createState() => _AudioPlayerShellState();
}

class _AudioPlayerShellState extends State<AudioPlayerShell> {
  bool _isPlaying = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSeconds = widget.session.durationMinutes * 60;
    final currentSeconds = (totalSeconds * _progress).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha:0.1),
        ),
      ),
      child: Column(
        children: [
          // Waveform Placeholder
          Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(30, (index) {
                // Generate pseudo-random heights for waveform bars
                final heights = [0.3, 0.5, 0.7, 0.4, 0.8, 0.6, 0.9, 0.5, 0.7, 0.4];
                final height = heights[index % heights.length];
                final isPlayed = index / 30 <= _progress;

                return Container(
                  width: 3,
                  height: 40 * height,
                  decoration: BoxDecoration(
                    color: isPlayed
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Progress Slider
          SliderTheme(
            data: SliderThemeData(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackHeight: 4,
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.primary.withValues(alpha:0.2),
              thumbColor: theme.colorScheme.primary,
            ),
            child: Slider(
              value: _progress,
              onChanged: (value) {
                setState(() => _progress = value);
              },
            ),
          ),

          // Time Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(currentSeconds),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                  ),
                ),
                Text(
                  _formatTime(totalSeconds),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind 15s
              IconButton(
                onPressed: () {
                  setState(() {
                    _progress = (_progress - 15 / totalSeconds).clamp(0.0, 1.0);
                  });
                },
                icon: const Icon(LucideIcons.rewind),
                color: theme.colorScheme.onSurface.withValues(alpha:0.6),
              ),
              const SizedBox(width: 16),

              // Play/Pause
              GestureDetector(
                onTap: () {
                  setState(() => _isPlaying = !_isPlaying);
                  // Note: Actual audio playback would be implemented here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isPlaying
                            ? 'Audio playback coming soon!'
                            : 'Paused',
                      ),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha:0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? LucideIcons.pause : LucideIcons.play,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Forward 15s
              IconButton(
                onPressed: () {
                  setState(() {
                    _progress = (_progress + 15 / totalSeconds).clamp(0.0, 1.0);
                  });
                },
                icon: const Icon(LucideIcons.fastForward),
                color: theme.colorScheme.onSurface.withValues(alpha:0.6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
