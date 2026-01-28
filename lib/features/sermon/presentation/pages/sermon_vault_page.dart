import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_cubit.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_state.dart';
import 'package:quick_church/features/sermon/presentation/pages/sermon_folder_page.dart';
import 'package:quick_church/features/sermon/presentation/pages/sermon_editor_page.dart';
import 'package:quick_church/features/sermon/presentation/widgets/folder_tile.dart';

/// Root page for the Sermon Vault feature.
/// Displays a search bar and iOS Notes-style folder list.
class SermonVaultPage extends StatefulWidget {
  const SermonVaultPage({super.key});

  @override
  State<SermonVaultPage> createState() => _SermonVaultPageState();
}

class _SermonVaultPageState extends State<SermonVaultPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initializeSermons();
  }

  void _initializeSermons() {
    // Get user ID from ProfileCubit and initialize SermonCubit
    final profileState = context.read<ProfileCubit>().state;
    String? userId;

    if (profileState is ProfileLoaded) {
      userId = profileState.profile.id;
    } else if (profileState is ProfileNeedsOnboarding) {
      userId = profileState.profile.id;
    }

    if (userId != null) {
      context.read<SermonCubit>().init(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<SermonCubit>().search(query);
    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SermonCubit>().clearSearch();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
    });
  }

  void _navigateToFolder(SermonFolder folder) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) =>
            BlocProvider.value(
          value: context.read<SermonCubit>(),
          child: SermonFolderPage(
            folderId: folder.id,
            folderName: folder.name,
            isAllSermons: folder.isAllSermons,
          ),
        ),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _createNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: context.read<SermonCubit>(),
          child: const SermonEditorPage(),
        ),
      ),
    );
  }

  void _createNewSeries() {
    _showCreateSeriesDialog();
  }

  Future<void> _showCreateSeriesDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'New Series',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Series Name',
                  hintText: 'e.g., "Faith Over Fear"',
                  labelStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result == true && nameController.text.trim().isNotEmpty && mounted) {
      await context.read<SermonCubit>().createSeries(
            title: nameController.text.trim(),
            description: descController.text.trim().isNotEmpty
                ? descController.text.trim()
                : null,
          );
    }

    nameController.dispose();
    descController.dispose();
  }

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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sermon Vault',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      // New Series button
                      IconButton(
                        onPressed: _createNewSeries,
                        tooltip: 'New Series',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            LucideIcons.folderPlus,
                            color: isDark ? Colors.white70 : Colors.black54,
                            size: 20,
                          ),
                        ),
                      ),
                      // New Note button
                      IconButton(
                        onPressed: _createNewNote,
                        tooltip: 'New Note',
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
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildSearchBar(context, isDark),
            ),

            // Content
            Expanded(
              child: BlocBuilder<SermonCubit, SermonState>(
                builder: (context, state) {
                  if (state is SermonLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state is SermonError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.alertCircle,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _initializeSermons,
                            icon: const Icon(LucideIcons.refreshCw),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is SermonLoaded) {
                    if (_isSearching) {
                      return _buildSearchResults(context, state, isDark);
                    }
                    return _buildFolderList(context, state, isDark);
                  }

                  return const Center(
                    child: Text('Start by adding your first sermon note!'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearch,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Search sermons, preachers, verses...',
          hintStyle: GoogleFonts.inter(
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: isDark ? Colors.white38 : Colors.black38,
            size: 20,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(
                    LucideIcons.x,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFolderList(BuildContext context, SermonLoaded state, bool isDark) {
    if (state.folders.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: state.folders.length,
      onReorder: (oldIndex, newIndex) {
        context.read<SermonCubit>().reorderFolders(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevationValue = Curves.easeInOut.transform(animation.value) * 8;
            return Material(
              elevation: elevationValue,
              borderRadius: BorderRadius.circular(16),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final folder = state.folders[index];
        return FolderTile(
          key: ValueKey(folder.id ?? folder.name),
          folder: folder,
          isDark: isDark,
          onTap: () => _navigateToFolder(folder),
          // Don't allow reordering "All Sermons" or "Uncategorized"
          canReorder: !folder.isAllSermons && folder.id != 'uncategorized',
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, SermonLoaded state, bool isDark) {
    final results = state.filteredNotes;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];
        return _buildSearchResultTile(context, note, isDark);
      },
    );
  }

  Widget _buildSearchResultTile(BuildContext context, SermonNote note, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            note.isPinned ? LucideIcons.pin : LucideIcons.fileText,
            color: AppTheme.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          note.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              note.preacher,
              style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (note.seriesTitle != null) ...[
              const SizedBox(height: 2),
              Text(
                note.seriesTitle!,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          color: isDark ? Colors.white24 : Colors.black26,
          size: 20,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => BlocProvider.value(
                value: context.read<SermonCubit>(),
                child: SermonEditorPage(noteId: note.id),
              ),
            ),
          );
        },
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.bookOpen,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Sermon Vault is Empty',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start capturing sermon notes and build your personal library of spiritual insights.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _createNewNote,
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add First Note'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
