import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_cubit.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_state.dart';
import 'package:quick_church/features/sermon/presentation/pages/sermon_editor_page.dart';
import 'package:quick_church/features/sermon/presentation/widgets/timeline_sermon_tile.dart';
import 'package:quick_church/features/sermon/presentation/widgets/vault_shimmer.dart';

/// Premium timeline-style sermon list page within a series/folder.
/// Features:
/// - Hero animation from grid card
/// - Timeline connector design
/// - Swipe actions (pin/delete)
/// - Grouped by date sections
/// - Breadcrumb navigation
/// - Move note to series
class SermonFolderPage extends StatefulWidget {
  final String? folderId;
  final String folderName;
  final bool isAllSermons;
  final String? folderColor;
  final String? folderIcon;

  const SermonFolderPage({
    super.key,
    this.folderId,
    required this.folderName,
    this.isAllSermons = false,
    this.folderColor,
    this.folderIcon,
  });

  @override
  State<SermonFolderPage> createState() => _SermonFolderPageState();
}

class _SermonFolderPageState extends State<SermonFolderPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Premium Header
          _buildSliverHeader(context, isDark),

          // Content
          SliverToBoxAdapter(
            child: BlocBuilder<SermonCubit, SermonState>(
              builder: (context, state) {
                if (state is SermonLoading || _isLoading) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SermonNoteShimmer(isDark: isDark, count: 5),
                  );
                }

                if (state is! SermonLoaded) {
                  return const SizedBox.shrink();
                }

                final notes = _getNotesForFolder(state);

                if (notes.isEmpty) {
                  return _buildEmptyState(context, isDark);
                }

                return _buildTimelineList(context, notes, isDark);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, isDark),
    );
  }

  Widget _buildSliverHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              color: isDark ? Colors.white : Colors.black87,
              size: 22,
            ),
          ),
        ),
      ),
      actions: [
        // Sort button
        IconButton(
          onPressed: () => _showSortOptions(context, isDark),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.arrowUpDown,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 18,
            ),
          ),
        ),
        // Add note button
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _addNote(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.plus,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Hero(
          tag: 'series_${widget.folderId ?? widget.folderName}',
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getFolderColor().withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getFolderIcon(),
                    color: _getFolderColor(),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.folderName,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      AppTheme.darkSurface,
                      AppTheme.darkBackground,
                    ]
                  : [
                      Colors.white,
                      AppTheme.lightBackground,
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 90, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb Navigation
                _buildBreadcrumb(context, isDark),
                const SizedBox(height: 16),
                // Stats Row
                BlocBuilder<SermonCubit, SermonState>(
                  builder: (context, state) {
                    if (state is! SermonLoaded) return const SizedBox.shrink();

                    final notes = _getNotesForFolder(state);
                    final pinnedCount = notes.where((n) => n.isPinned).length;

                    return Row(
                      children: [
                        _buildStatChip(
                          icon: LucideIcons.fileText,
                          label: '${notes.length} notes',
                          color: AppTheme.primaryColor,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        if (pinnedCount > 0)
                          _buildStatChip(
                            icon: LucideIcons.pin,
                            label: '$pinnedCount pinned',
                            color: AppTheme.goldenPromise,
                            isDark: isDark,
                          ),
                      ],
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.library,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            'Sermon Vault',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            LucideIcons.chevronRight,
            size: 14,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getFolderColor().withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getFolderColor().withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getFolderIcon(),
                  size: 12,
                  color: _getFolderColor(),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.folderName.length > 20
                      ? '${widget.folderName.substring(0, 20)}...'
                      : widget.folderName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getFolderColor(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0);
  }

  Widget _buildTimelineList(BuildContext context, List<SermonNote> notes, bool isDark) {
    // Separate pinned and unpinned
    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final unpinnedNotes = notes.where((n) => !n.isPinned).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinned Section
          if (pinnedNotes.isNotEmpty) ...[
            _buildSectionTitle('Pinned', LucideIcons.pin, AppTheme.goldenPromise, isDark)
                .animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 12),
            ...pinnedNotes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;
              return TimelineSermonTile(
                note: note,
                isDark: isDark,
                isFirst: index == 0,
                isLast: index == pinnedNotes.length - 1 && unpinnedNotes.isEmpty,
                onTap: () => _openNote(context, note),
                onDelete: () => _deleteNote(context, note),
                onTogglePin: () => _togglePin(context, note),
                onMove: () => _showMoveNoteSheet(context, note, isDark),
              ).animate().fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: 100 + (index * 50)),
              ).slideX(begin: 0.05, end: 0);
            }),
            if (unpinnedNotes.isNotEmpty) const SizedBox(height: 24),
          ],

          // All Notes Section
          if (unpinnedNotes.isNotEmpty) ...[
            if (pinnedNotes.isNotEmpty)
              _buildSectionTitle('Notes', LucideIcons.fileText, AppTheme.primaryColor, isDark)
                  .animate().fadeIn(duration: 400.ms, delay: 200.ms),
            if (pinnedNotes.isNotEmpty) const SizedBox(height: 12),
            ...unpinnedNotes.asMap().entries.map((entry) {
              final index = entry.key;
              final note = entry.value;
              return TimelineSermonTile(
                note: note,
                isDark: isDark,
                isFirst: pinnedNotes.isEmpty && index == 0,
                isLast: index == unpinnedNotes.length - 1,
                onTap: () => _openNote(context, note),
                onDelete: () => _deleteNote(context, note),
                onTogglePin: () => _togglePin(context, note),
                onMove: () => _showMoveNoteSheet(context, note, isDark),
              ).animate().fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: (pinnedNotes.length * 50) + 150 + (index * 50)),
              ).slideX(begin: 0.05, end: 0);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _getFolderColor().withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.fileText,
              size: 48,
              color: _getFolderColor(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notes Yet',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isAllSermons
                ? 'Your sermon vault is empty.\nStart capturing your spiritual insights!'
                : 'Add notes to "${widget.folderName}"\nto start building this series.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _addNote(context),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add Note'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ).animate()
          .fadeIn(duration: 500.ms)
          .scale(begin: const Offset(0.95, 0.95)),
    );
  }

  Widget _buildFAB(BuildContext context, bool isDark) {
    return FloatingActionButton(
      onPressed: () => _addNote(context),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      child: const Icon(LucideIcons.plus),
    ).animate()
        .fadeIn(duration: 400.ms, delay: 500.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  List<SermonNote> _getNotesForFolder(SermonLoaded state) {
    if (widget.isAllSermons || widget.folderId == null) {
      return List.from(state.notes)
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.sermonDate.compareTo(a.sermonDate);
        });
    }

    if (widget.folderId == 'uncategorized') {
      return state.notes.where((n) => n.seriesId == null).toList()
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.sermonDate.compareTo(a.sermonDate);
        });
    }

    return state.notes.where((n) => n.seriesId == widget.folderId).toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.sermonDate.compareTo(a.sermonDate);
      });
  }

  IconData _getFolderIcon() {
    if (widget.isAllSermons) return LucideIcons.library;
    if (widget.folderId == 'uncategorized') return LucideIcons.inbox;

    // Use passed icon or fallback
    if (widget.folderIcon != null) {
      return _mapIconStringToIconData(widget.folderIcon!);
    }
    return LucideIcons.folder;
  }

  IconData _mapIconStringToIconData(String iconName) {
    switch (iconName) {
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
      case 'crown':
        return LucideIcons.crown;
      case 'sun':
        return LucideIcons.sun;
      case 'mountain':
        return LucideIcons.mountain;
      case 'anchor':
        return LucideIcons.anchor;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'inbox':
        return LucideIcons.inbox;
      default:
        return LucideIcons.folder;
    }
  }

  Color _getFolderColor() {
    if (widget.isAllSermons) return AppTheme.primaryColor;
    if (widget.folderId == 'uncategorized') return const Color(0xFF9E9E9E);

    // Use passed color or fallback
    if (widget.folderColor != null) {
      try {
        final hexColor = widget.folderColor!.replaceFirst('#', '');
        return Color(int.parse('FF$hexColor', radix: 16));
      } catch (_) {
        // Fallback on parse error
      }
    }

    final colors = [
      const Color(0xFFFF9500),
      const Color(0xFF30D158),
      const Color(0xFF5856D6),
      const Color(0xFFFF375F),
      const Color(0xFF64D2FF),
      const Color(0xFFFFD60A),
    ];
    return colors[widget.folderName.hashCode.abs() % colors.length];
  }

  void _addNote(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: context.read<SermonCubit>(),
          child: SermonEditorPage(
            initialSeriesId: widget.isAllSermons ? null : widget.folderId,
            initialSeries: widget.isAllSermons ? null : widget.folderName,
          ),
        ),
      ),
    );
  }

  void _openNote(BuildContext context, SermonNote note) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: context.read<SermonCubit>(),
          child: SermonEditorPage(noteId: note.id),
        ),
      ),
    );
  }

  void _deleteNote(BuildContext context, SermonNote note) {
    HapticFeedback.mediumImpact();
    context.read<SermonCubit>().deleteSermon(note.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${note.title}"'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // TODO: Implement undo
          },
        ),
      ),
    );
  }

  void _togglePin(BuildContext context, SermonNote note) {
    HapticFeedback.mediumImpact();
    context.read<SermonCubit>().togglePin(note.id);
  }

  void _showMoveNoteSheet(BuildContext context, SermonNote note, bool isDark) {
    HapticFeedback.mediumImpact();
    final cubit = context.read<SermonCubit>();
    final state = cubit.state;

    if (state is! SermonLoaded) return;

    // Get available series (excluding current series)
    final availableFolders = state.folders
        .where((f) => !f.isAllSermons && f.id != note.seriesId)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.folderInput,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Move Note',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select a series for "${note.title}"',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.black.withAlpha(20),
              ),
              // Series List
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  itemCount: availableFolders.length,
                  itemBuilder: (ctx, index) {
                    final folder = availableFolders[index];
                    final isUncategorized = folder.id == 'uncategorized';
                    final folderColor = _parseFolderColor(folder.color);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: folderColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: folderColor.withAlpha(40),
                          ),
                        ),
                        child: Icon(
                          _mapIconStringToIconData(folder.icon),
                          color: folderColor,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        folder.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${folder.noteCount} notes',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      trailing: Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);

                        // Update the note's seriesId
                        late final SermonNote updatedNote;
                        if (isUncategorized) {
                          // Move to uncategorized - clear the series
                          updatedNote = note.copyWith(
                            clearSeriesId: true,
                            seriesTitle: null,
                          );
                        } else {
                          // Move to a specific series
                          updatedNote = note.copyWith(
                            seriesId: folder.id,
                            seriesTitle: folder.name,
                          );
                        }

                        await cubit.saveNote(updatedNote);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Moved to "${folder.name}"',
                                style: GoogleFonts.inter(),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  // Revert the move
                                  await cubit.saveNote(note);
                                },
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              // Create New Series Option
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // TODO: Open create series dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Create a new series from the Sermon Vault',
                          style: GoogleFonts.inter(),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.folderPlus, size: 18),
                  label: const Text('Create New Series'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: AppTheme.primaryColor.withAlpha(100),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _parseFolderColor(String colorString) {
    try {
      final hexColor = colorString.replaceFirst('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  void _showSortOptions(BuildContext context, bool isDark) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              const SizedBox(height: 20),
              Text(
                'Sort By',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption(
                context,
                'Date (Newest)',
                LucideIcons.calendarDays,
                true,
                isDark,
              ),
              _buildSortOption(
                context,
                'Date (Oldest)',
                LucideIcons.calendar,
                false,
                isDark,
              ),
              _buildSortOption(
                context,
                'Title (A-Z)',
                LucideIcons.arrowDownAZ,
                false,
                isDark,
              ),
              _buildSortOption(
                context,
                'Speaker',
                LucideIcons.mic2,
                false,
                isDark,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    bool isDark,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white54 : Colors.black45),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      trailing: isSelected
          ? const Icon(LucideIcons.check, color: AppTheme.primaryColor)
          : null,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context);
        // TODO: Implement sorting
      },
    );
  }
}
