import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';

/// iOS Notes-style folder tile for the Sermon Vault.
class FolderTile extends StatelessWidget {
  final SermonFolder folder;
  final bool isDark;
  final VoidCallback onTap;
  final bool canReorder;

  const FolderTile({
    super.key,
    required this.folder,
    required this.isDark,
    required this.onTap,
    this.canReorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Hero(
            tag: 'folder_${folder.name}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Folder Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getFolderColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFolderIcon(),
                      color: _getFolderColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Folder Name & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (folder.lastUpdated != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(folder.lastUpdated!),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Note Count & Chevron
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${folder.noteCount}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.chevronRight,
                        color: isDark ? Colors.white24 : Colors.black26,
                        size: 20,
                      ),
                    ],
                  ),

                  // Reorder Handle
                  if (canReorder) ...[
                    const SizedBox(width: 8),
                    ReorderableDragStartListener(
                      index: 0, // Will be set by parent
                      child: Icon(
                        LucideIcons.gripVertical,
                        color: isDark ? Colors.white24 : Colors.black26,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFolderIcon() {
    if (folder.isAllSermons) {
      return LucideIcons.library;
    }
    return LucideIcons.folder;
  }

  Color _getFolderColor() {
    if (folder.isAllSermons) {
      return AppTheme.primaryColor;
    }
    // Generate consistent color based on folder name
    final colors = [
      const Color(0xFFFF9500), // Orange
      const Color(0xFF30D158), // Green
      const Color(0xFF5856D6), // Purple
      const Color(0xFFFF375F), // Pink
      const Color(0xFF64D2FF), // Cyan
      const Color(0xFFFFD60A), // Yellow
    ];
    final index = folder.name.hashCode.abs() % colors.length;
    return colors[index];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Updated today';
    } else if (diff.inDays == 1) {
      return 'Updated yesterday';
    } else if (diff.inDays < 7) {
      return 'Updated ${diff.inDays} days ago';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return 'Updated ${months[date.month - 1]} ${date.day}';
    }
  }
}
