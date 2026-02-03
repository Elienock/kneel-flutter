import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';

/// Premium timeline-style sermon note tile for the Digital Sanctuary.
/// Features:
/// - Timeline connector line
/// - Date marker
/// - Slide-to-reveal actions
/// - Rich metadata display
class TimelineSermonTile extends StatelessWidget {
  final SermonNote note;
  final bool isDark;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePin;
  final VoidCallback? onShare;
  final VoidCallback? onMove;

  const TimelineSermonTile({
    super.key,
    required this.note,
    required this.isDark,
    this.isFirst = false,
    this.isLast = false,
    required this.onTap,
    this.onDelete,
    this.onTogglePin,
    this.onShare,
    this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline Column
            _buildTimelineColumn(),
            const SizedBox(width: 16),

            // Card
            Expanded(
              child: _buildNoteCard(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineColumn() {
    final dotColor = note.isPinned
        ? AppTheme.goldenPromise
        : AppTheme.primaryColor;

    return SizedBox(
      width: 24,
      child: Column(
        children: [
          // Top connector
          if (!isFirst)
            Expanded(
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dotColor.withAlpha(80),
                      dotColor.withAlpha(150),
                    ],
                  ),
                ),
              ),
            ),

          // Date dot
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withAlpha(100),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: note.isPinned
                ? const Icon(
                    LucideIcons.pin,
                    size: 8,
                    color: Colors.white,
                  )
                : null,
          ),

          // Bottom connector
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      dotColor.withAlpha(150),
                      dotColor.withAlpha(50),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context) {
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.horizontal,
      background: _buildSwipeBackground(true),
      secondaryBackground: _buildSwipeBackground(false),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          // Pin action
          onTogglePin?.call();
          return false;
        } else {
          // Delete action - show confirmation
          return await _showDeleteConfirmation(context);
        }
      },
      onDismissed: (_) => onDelete?.call(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: () => _showOptionsMenu(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: note.isPinned
                ? Border.all(
                    color: AppTheme.goldenPromise.withAlpha(60),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date & Pin
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatSermonDate(note.sermonDate),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  if (note.isPinned) ...[
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.pin,
                      size: 14,
                      color: AppTheme.goldenPromise,
                    ),
                  ],
                  const Spacer(),
                  // Verse badge
                  if (note.verse != null && note.verse!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(10)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.bookOpen,
                            size: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            note.verse!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                note.title,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Preacher
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      LucideIcons.mic2,
                      size: 14,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note.preacher,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),

              // Preview of content
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _extractPreviewText(note.content),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Tags
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(8)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withAlpha(10)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(bool isLeft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLeft
            ? AppTheme.goldenPromise.withAlpha(30)
            : Colors.red.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(
        isLeft
            ? (note.isPinned ? LucideIcons.pinOff : LucideIcons.pin)
            : LucideIcons.trash2,
        color: isLeft ? AppTheme.goldenPromise : Colors.red,
        size: 24,
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  note.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  note.preacher,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 20),
                // Options Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      context,
                      icon: note.isPinned ? LucideIcons.pinOff : LucideIcons.pin,
                      label: note.isPinned ? 'Unpin' : 'Pin',
                      color: AppTheme.goldenPromise,
                      onTap: () {
                        Navigator.pop(ctx);
                        onTogglePin?.call();
                      },
                    ),
                    _buildOptionButton(
                      context,
                      icon: LucideIcons.folderInput,
                      label: 'Move',
                      color: AppTheme.primaryColor,
                      onTap: () {
                        Navigator.pop(ctx);
                        onMove?.call();
                      },
                    ),
                    _buildOptionButton(
                      context,
                      icon: LucideIcons.share2,
                      label: 'Share',
                      color: const Color(0xFF30D158),
                      onTap: () {
                        Navigator.pop(ctx);
                        onShare?.call();
                      },
                    ),
                    _buildOptionButton(
                      context,
                      icon: LucideIcons.trash2,
                      label: 'Delete',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showDeleteConfirmation(context).then((confirmed) {
                          if (confirmed) onDelete?.call();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Delete "${note.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _formatSermonDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return weekdays[date.weekday % 7];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Extracts plain text preview from content (handles JSON Delta format).
  String _extractPreviewText(String content) {
    if (content.isEmpty) return '';

    // Check if it's JSON (Quill Delta format)
    if (content.startsWith('[')) {
      try {
        // Sanitize and parse the JSON
        final sanitized = content.replaceAll(
          RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
          '',
        );
        final delta = jsonDecode(sanitized) as List<dynamic>;
        final buffer = StringBuffer();
        for (final op in delta) {
          if (op is Map && op['insert'] is String) {
            buffer.write(op['insert']);
          }
        }
        final text = buffer.toString().trim();
        // Get first meaningful line
        final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
        return lines.isNotEmpty ? lines.first : '';
      } catch (_) {
        // If parsing fails, return empty or first part of raw content
        return '';
      }
    }

    // Plain text - just get first line
    return content.split('\n').first.trim();
  }
}
