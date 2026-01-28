import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_cubit.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_state.dart';
import 'package:quick_church/features/sermon/presentation/pages/sermon_editor_page.dart';
import 'package:quick_church/features/sermon/presentation/widgets/sermon_note_tile.dart';

/// Sub-page displaying sermon notes within a specific folder/series.
/// Uses Hero animations for smooth transitions from the folder list.
class SermonFolderPage extends StatelessWidget {
  final String? folderId;
  final String folderName;
  final bool isAllSermons;

  const SermonFolderPage({
    super.key,
    this.folderId,
    required this.folderName,
    this.isAllSermons = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header
            Hero(
              tag: 'folder_${folderId ?? folderName}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button Row
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                LucideIcons.arrowLeft,
                                color: isDark ? Colors.white : Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => BlocProvider.value(
                                    value: context.read<SermonCubit>(),
                                    child: SermonEditorPage(
                                      initialSeriesId: isAllSermons ? null : folderId,
                                      initialSeries: isAllSermons ? null : folderName,
                                    ),
                                  ),
                                ),
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                LucideIcons.plus,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Folder Icon & Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getFolderColor().withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _getFolderIcon(),
                              color: _getFolderColor(),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              folderName,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Notes List
            Expanded(
              child: BlocBuilder<SermonCubit, SermonState>(
                builder: (context, state) {
                  if (state is! SermonLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Get notes based on folder
                  final notes = _getNotesForFolder(state);

                  if (notes.isEmpty) {
                    return _buildEmptyState(context, isDark);
                  }

                  // Separate pinned and unpinned notes
                  final pinnedNotes = notes.where((n) => n.isPinned).toList();
                  final unpinnedNotes = notes.where((n) => !n.isPinned).toList();

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Pinned Section
                      if (pinnedNotes.isNotEmpty) ...[
                        _buildSectionHeader(context, 'Pinned', isDark),
                        const SizedBox(height: 12),
                        ...pinnedNotes.map((note) => SermonNoteTile(
                              note: note,
                              isDark: isDark,
                              onTap: () => _openNote(context, note),
                              onDelete: () => _deleteNote(context, note),
                              onTogglePin: () => _togglePin(context, note),
                            )),
                        const SizedBox(height: 20),
                      ],

                      // All Notes Section
                      if (unpinnedNotes.isNotEmpty) ...[
                        if (pinnedNotes.isNotEmpty)
                          _buildSectionHeader(context, 'Notes', isDark),
                        if (pinnedNotes.isNotEmpty) const SizedBox(height: 12),
                        ...unpinnedNotes.map((note) => SermonNoteTile(
                              note: note,
                              isDark: isDark,
                              onTap: () => _openNote(context, note),
                              onDelete: () => _deleteNote(context, note),
                              onTogglePin: () => _togglePin(context, note),
                            )),
                      ],

                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SermonNote> _getNotesForFolder(SermonLoaded state) {
    if (isAllSermons || folderId == null) {
      // All Sermons
      return List.from(state.notes)
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.sermonDate.compareTo(a.sermonDate);
        });
    }

    if (folderId == 'uncategorized') {
      // Uncategorized notes
      return state.notes
          .where((n) => n.seriesId == null)
          .toList()
        ..sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.sermonDate.compareTo(a.sermonDate);
        });
    }

    // Specific series
    return state.notes
        .where((n) => n.seriesId == folderId)
        .toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.sermonDate.compareTo(a.sermonDate);
      });
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white54 : Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.fileText,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
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
              isAllSermons
                  ? 'Add your first sermon note to get started'
                  : 'Add notes to this series',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => BlocProvider.value(
                      value: context.read<SermonCubit>(),
                      child: SermonEditorPage(
                        initialSeriesId: isAllSermons ? null : folderId,
                        initialSeries: isAllSermons ? null : folderName,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Note'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFolderIcon() {
    if (isAllSermons) return LucideIcons.library;
    if (folderId == 'uncategorized') return LucideIcons.inbox;
    return LucideIcons.folder;
  }

  Color _getFolderColor() {
    if (isAllSermons) return AppTheme.primaryColor;
    if (folderId == 'uncategorized') return const Color(0xFF9E9E9E);

    final colors = [
      const Color(0xFFFF9500),
      const Color(0xFF30D158),
      const Color(0xFF5856D6),
      const Color(0xFFFF375F),
      const Color(0xFF64D2FF),
      const Color(0xFFFFD60A),
    ];
    final index = folderName.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _openNote(BuildContext context, SermonNote note) {
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SermonCubit>().deleteSermon(note.id);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _togglePin(BuildContext context, SermonNote note) {
    context.read<SermonCubit>().togglePin(note.id);
  }
}
