import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/insights/domain/entities/user_session.dart';

/// Prominent streak display widget with animated fire icon.
/// Shows current streak count with motivational messaging.
class StreakDisplay extends StatelessWidget {
  final StreakStats stats;
  final VoidCallback? onTap;

  const StreakDisplay({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasStreak = stats.currentStreak > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: hasStreak
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withAlpha(200),
                  ],
                )
              : null,
          color: hasStreak
              ? null
              : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: hasStreak
              ? null
              : Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
          boxShadow: hasStreak
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Fire icon with glow effect
            _buildFireIcon(hasStreak, isDark),
            const SizedBox(width: 16),

            // Streak info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${stats.currentStreak}',
                        style: GoogleFonts.outfit(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: hasStreak
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.black38),
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stats.currentStreak == 1 ? 'day' : 'days',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: hasStreak
                              ? Colors.white70
                              : (isDark ? Colors.white38 : Colors.black26),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats.motivationalMessage,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hasStreak
                          ? Colors.white.withAlpha(200)
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Longest streak badge
            if (stats.longestStreak > 0)
              _buildLongestStreakBadge(hasStreak, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFireIcon(bool hasStreak, bool isDark) {
    final icon = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: hasStreak
            ? Colors.white.withAlpha(30)
            : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          LucideIcons.flame,
          size: 36,
          color: hasStreak
              ? AppTheme.goldenPromise
              : (isDark ? Colors.white38 : Colors.black26),
        ),
      ),
    );

    if (!hasStreak) return icon;

    // Animated fire for active streaks
    return icon
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 1500.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .shimmer(
          duration: 2000.ms,
          color: AppTheme.goldenPromise.withAlpha(60),
        );
  }

  Widget _buildLongestStreakBadge(bool hasStreak, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasStreak
            ? Colors.white.withAlpha(25)
            : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.trophy,
            size: 18,
            color: hasStreak
                ? AppTheme.goldenPromise
                : (isDark ? Colors.white38 : Colors.black38),
          ),
          const SizedBox(height: 4),
          Text(
            '${stats.longestStreak}',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: hasStreak
                  ? Colors.white
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
          Text(
            'best',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: hasStreak
                  ? Colors.white60
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact streak indicator for app bars or small spaces.
class StreakIndicator extends StatelessWidget {
  final int currentStreak;
  final bool showLabel;
  final double iconSize;

  const StreakIndicator({
    super.key,
    required this.currentStreak,
    this.showLabel = true,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStreak = currentStreak > 0;

    Widget indicator = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.flame,
          size: iconSize,
          color: hasStreak
              ? AppTheme.goldenPromise
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '$currentStreak',
          style: GoogleFonts.inter(
            fontSize: iconSize * 0.8,
            fontWeight: FontWeight.w700,
            color: hasStreak
                ? AppTheme.primaryColor
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 2),
          Text(
            'd',
            style: GoogleFonts.inter(
              fontSize: iconSize * 0.6,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (hasStreak) {
      indicator = indicator
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.02, 1.02),
            duration: 2000.ms,
          );
    }

    return indicator;
  }
}
