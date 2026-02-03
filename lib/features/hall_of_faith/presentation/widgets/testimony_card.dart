import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';

/// A beautiful masonry card for displaying answered prayers in the Hall of Faith.
/// Features a gold inner glow, victory badge, and image support.
class TestimonyCard extends StatelessWidget {
  final Prayer prayer;
  final VoidCallback? onTap;
  final int index;

  const TestimonyCard({
    super.key,
    required this.prayer,
    this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasImage = prayer.testimonyImageUrl != null &&
        prayer.testimonyImageUrl!.isNotEmpty;
    final hasTestimony = prayer.testimony != null && prayer.testimony!.isNotEmpty;

    // Calculate card height based on content
    final baseHeight = hasImage ? 220.0 : 160.0;
    final contentHeight = hasTestimony ? 60.0 : 0.0;
    final totalHeight = baseHeight + contentHeight;

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'testimony_${prayer.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            height: totalHeight,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppTheme.goldenPromise.withAlpha(40)
                    : AppTheme.goldenPromise.withAlpha(30),
              ),
              boxShadow: [
                // Gold inner glow effect
                BoxShadow(
                  color: AppTheme.goldenPromise.withAlpha(isDark ? 25 : 15),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
                // Subtle shadow
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 40 : 20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Background image if present
                  if (hasImage)
                    Positioned.fill(
                      child: _buildImage(),
                    ),

                  // Gradient overlay for readability
                  if (hasImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(180),
                            ],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Victory badge
                        _buildVictoryBadge(isDark),
                        const Spacer(),

                        // Prayer title
                        Text(
                          prayer.title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: hasImage
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Answered date
                        if (prayer.answeredAt != null)
                          Text(
                            'Answered ${_formatDate(prayer.answeredAt!)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: hasImage
                                  ? AppTheme.goldenPromise
                                  : AppTheme.goldenPromise.withAlpha(200),
                            ),
                          ),

                        // Testimony snippet
                        if (hasTestimony) ...[
                          const SizedBox(height: 8),
                          Text(
                            prayer.testimony!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: hasImage
                                  ? Colors.white70
                                  : (isDark ? Colors.white60 : Colors.black54),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Public indicator
                        if (prayer.isPublicTestimony) ...[
                          const SizedBox(height: 8),
                          _buildPublicBadge(hasImage),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: index * 50),
        ).slideY(
          begin: 0.1,
          end: 0,
          duration: 400.ms,
          delay: Duration(milliseconds: index * 50),
          curve: Curves.easeOut,
        );
  }

  Widget _buildImage() {
    return Image.network(
      prayer.testimonyImageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: AppTheme.goldenPromise,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        return Container(
          color: AppTheme.primaryColor.withAlpha(20),
          child: const Center(
            child: Icon(
              LucideIcons.imagePlus,
              size: 32,
              color: AppTheme.primaryColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVictoryBadge(bool isDark) {
    return Row(
      children: [
        // Victory badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.goldenPromise.withAlpha(isDark ? 50 : 40),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.goldenPromise.withAlpha(80),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.trophy,
                size: 14,
                color: AppTheme.goldenPromise,
              ),
              const SizedBox(width: 6),
              Text(
                'Victory',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.goldenPromise,
                ),
              ),
            ],
          ),
        ),
        // Persistence badge - shows how many times prayed
        if (prayer.prayerCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(isDark ? 15 : 10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.flame,
                  size: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  '${prayer.prayerCount}×',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPublicBadge(bool hasImage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.globe,
          size: 12,
          color: hasImage ? Colors.white54 : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          'Shared',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: hasImage ? Colors.white54 : Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
