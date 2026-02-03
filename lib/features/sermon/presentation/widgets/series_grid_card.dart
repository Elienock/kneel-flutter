import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';

/// Premium glassmorphism-style card for sermon series in the Digital Sanctuary.
/// Features:
/// - Subtle glass effect with blur
/// - Animated note count badge
/// - Color-coded by series
/// - Long-press for options
class SeriesGridCard extends StatelessWidget {
  final SermonFolder folder;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isCompact;

  const SeriesGridCard({
    super.key,
    required this.folder,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final folderColor = _getFolderColor();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Hero(
        tag: 'series_${folder.id ?? folder.name}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: folderColor.withAlpha(isDark ? 40 : 25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 60 : 15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(isCompact ? 14 : 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF2A2A2A).withAlpha(230),
                            const Color(0xFF1E1E1E).withAlpha(240),
                          ]
                        : [
                            Colors.white.withAlpha(240),
                            Colors.white.withAlpha(220),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(15)
                        : Colors.black.withAlpha(8),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Series Icon
                        Container(
                          padding: EdgeInsets.all(isCompact ? 10 : 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                folderColor.withAlpha(50),
                                folderColor.withAlpha(30),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: folderColor.withAlpha(40),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _getFolderIcon(),
                            color: folderColor,
                            size: isCompact ? 22 : 26,
                          ),
                        ),

                        // Note Count Badge & Edit Icon
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit button (triggers long press)
                            if (onLongPress != null)
                              GestureDetector(
                                onTap: onLongPress,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withAlpha(10)
                                        : Colors.black.withAlpha(5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    LucideIcons.moreHorizontal,
                                    size: isCompact ? 14 : 16,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                              ),
                            if (onLongPress != null) const SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 10 : 12,
                                vertical: isCompact ? 5 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha(15)
                                    : Colors.black.withAlpha(8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.fileText,
                                    size: isCompact ? 12 : 14,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${folder.noteCount}',
                                    style: GoogleFonts.outfit(
                                      fontSize: isCompact ? 13 : 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Title
                    Text(
                      folder.name,
                      style: GoogleFonts.outfit(
                        fontSize: isCompact ? 15 : 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (!isCompact && folder.lastUpdated != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(folder.lastUpdated!),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Progress indicator (visual element)
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isDark
                            ? Colors.white.withAlpha(10)
                            : Colors.black.withAlpha(8),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (folder.noteCount / 20).clamp(0.1, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                folderColor,
                                folderColor.withAlpha(180),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFolderIcon() {
    if (folder.isAllSermons) return LucideIcons.library;
    if (folder.id == 'uncategorized') return LucideIcons.inbox;

    // Map icon string to IconData
    switch (folder.icon) {
      case 'book':
        return LucideIcons.bookOpen;
      case 'heart':
        return LucideIcons.heart;
      case 'star':
        return LucideIcons.star;
      case 'flame':
        return LucideIcons.flame;
      case 'cross':
        return LucideIcons.cross;
      case 'church':
        return LucideIcons.church;
      default:
        return LucideIcons.folder;
    }
  }

  Color _getFolderColor() {
    if (folder.isAllSermons) return AppTheme.primaryColor;
    if (folder.id == 'uncategorized') return const Color(0xFF9E9E9E);

    // Try to parse hex color from folder
    try {
      final hexColor = folder.color.replaceFirst('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (_) {
      // Fallback to hash-based color
      final colors = [
        const Color(0xFFFF9500),
        const Color(0xFF30D158),
        const Color(0xFF5856D6),
        const Color(0xFFFF375F),
        const Color(0xFF64D2FF),
        const Color(0xFFFFD60A),
        const Color(0xFFBF5AF2),
        const Color(0xFF32ADE6),
      ];
      return colors[folder.name.hashCode.abs() % colors.length];
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
