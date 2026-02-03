import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:quick_church/features/sermon/presentation/widgets/series_grid_card.dart';
import 'package:quick_church/features/sermon/presentation/widgets/vault_shimmer.dart';

/// The "Digital Sanctuary" - Production-ready Sermon Vault.
/// Features:
/// - Logo header with sync status
/// - Global search bar
/// - 2-column grid for sermon series
/// - Shimmer loading effects
/// - Premium glassmorphism design
class SermonVaultPage extends StatefulWidget {
  const SermonVaultPage({super.key});

  @override
  State<SermonVaultPage> createState() => _SermonVaultPageState();
}

class _SermonVaultPageState extends State<SermonVaultPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  SyncStatus _syncStatus = SyncStatus.synced;

  @override
  void initState() {
    super.initState();
    _initializeSermons();
  }

  void _initializeSermons() {
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
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secondaryAnimation) => BlocProvider.value(
          value: context.read<SermonCubit>(),
          child: SermonFolderPage(
            folderId: folder.id,
            folderName: folder.name,
            isAllSermons: folder.isAllSermons,
            folderColor: folder.color,
            folderIcon: folder.icon,
          ),
        ),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _createNewNote() {
    HapticFeedback.mediumImpact();
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
    HapticFeedback.mediumImpact();
    _showCreateSeriesDialog();
  }

  Future<void> _showCreateSeriesDialog() async {
    final nameController = TextEditingController();
    final speakerController = TextEditingController();
    String selectedColor = '#673AB7';
    String selectedIcon = 'folder';
    String selectedCategory = 'General';

    // Kneel brand colors - Purple primary, Gold accent
    final colors = [
      '#673AB7', // Kneel Purple (Primary)
      '#D4AF37', // Kneel Gold (Accent)
      '#9C27B0', // Deep Purple
      '#E91E63', // Pink
      '#F44336', // Red
      '#FF9800', // Orange
      '#4CAF50', // Green
      '#009688', // Teal
      '#00BCD4', // Cyan
      '#2196F3', // Blue
      '#3F51B5', // Indigo
      '#607D8B', // Blue Grey
    ];

    // Modern Lucide icons for series
    final icons = [
      ('folder', LucideIcons.folderOpen, 'Folder'),
      ('bookshelf', LucideIcons.library, 'Bookshelf'),
      ('book', LucideIcons.bookOpen, 'Bible'),
      ('scroll', LucideIcons.scroll, 'Scroll'),
      ('heart', LucideIcons.heart, 'Heart'),
      ('star', LucideIcons.star, 'Star'),
      ('flame', LucideIcons.flame, 'Fire'),
      ('cross', LucideIcons.cross, 'Cross'),
      ('church', LucideIcons.church, 'Church'),
      ('crown', LucideIcons.crown, 'Crown'),
      ('sun', LucideIcons.sun, 'Light'),
      ('mountain', LucideIcons.mountain, 'Mountain'),
    ];

    // Categories for organization
    final categories = [
      'General',
      'Sunday Service',
      'Bible Study',
      'Youth',
      'Prayer Meeting',
      'Conference',
      'Special Event',
      'Guest Speaker',
    ];

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final colorValue = Color(int.parse('FF${selectedColor.substring(1)}', radix: 16));

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header with icon preview
                    Row(
                      children: [
                        // Icon Preview
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorValue,
                                colorValue.withAlpha(180),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorValue.withAlpha(80),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            icons.firstWhere((i) => i.$1 == selectedIcon).$2,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Series',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Organize your sermon notes',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Series Name field
                    _buildInputField(
                      controller: nameController,
                      label: 'Series Title',
                      hint: 'e.g., "Faith Over Fear"',
                      icon: LucideIcons.type,
                      iconColor: colorValue,
                      isDark: isDark,
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),

                    // Speaker field (optional)
                    _buildInputField(
                      controller: speakerController,
                      label: 'Default Speaker (optional)',
                      hint: 'e.g., "Pastor John"',
                      icon: LucideIcons.mic2,
                      iconColor: isDark ? Colors.white54 : Colors.black45,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade300,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          borderRadius: BorderRadius.circular(14),
                          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                          icon: Icon(
                            LucideIcons.chevronDown,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          items: categories.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(cat),
                                  size: 18,
                                  color: colorValue,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  cat,
                                  style: GoogleFonts.inter(
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() => selectedCategory = value);
                              HapticFeedback.selectionClick();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Color picker
                    Text(
                      'Theme Color',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: colors.map((color) {
                        final isSelected = color == selectedColor;
                        final clr = Color(int.parse('FF${color.substring(1)}', radix: 16));
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedColor = color);
                            HapticFeedback.selectionClick();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 44 : 38,
                            height: isSelected ? 44 : 38,
                            decoration: BoxDecoration(
                              color: clr,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : Border.all(color: clr.withAlpha(50), width: 2),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: clr.withAlpha(100), blurRadius: 12)]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(LucideIcons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Icon picker
                    Text(
                      'Series Icon',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: icons.map((iconData) {
                        final isSelected = iconData.$1 == selectedIcon;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedIcon = iconData.$1);
                            HapticFeedback.selectionClick();
                          },
                          child: Tooltip(
                            message: iconData.$3,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorValue.withAlpha(25)
                                    : (isDark ? Colors.white.withAlpha(8) : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: colorValue, width: 2)
                                    : Border.all(
                                        color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
                                      ),
                              ),
                              child: Icon(
                                iconData.$2,
                                color: isSelected
                                    ? colorValue
                                    : (isDark ? Colors.white54 : Colors.black45),
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, null),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () {
                              if (nameController.text.trim().isNotEmpty) {
                                Navigator.pop(context, {
                                  'name': nameController.text.trim(),
                                  'speaker': speakerController.text.trim(),
                                  'category': selectedCategory,
                                  'color': selectedColor,
                                  'icon': selectedIcon,
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Please enter a series name'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: colorValue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(LucideIcons.folderPlus, size: 20),
                            label: Text(
                              'Create Series',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _syncStatus = SyncStatus.syncing);

      // Build description from speaker and category
      String? description;
      final parts = <String>[];
      if (result['speaker']?.isNotEmpty == true) {
        parts.add('Speaker: ${result['speaker']}');
      }
      if (result['category'] != 'General') {
        parts.add('Category: ${result['category']}');
      }
      if (parts.isNotEmpty) {
        description = parts.join(' | ');
      }

      await context.read<SermonCubit>().createSeries(
        title: result['name'],
        description: description,
        color: result['color'],
        icon: result['icon'],
      );

      if (mounted) {
        setState(() => _syncStatus = SyncStatus.synced);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Text('Created "${result['name']}" series'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }

    nameController.dispose();
    speakerController.dispose();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofocus: autofocus,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            prefixIcon: Icon(icon, color: iconColor, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: iconColor, width: 2),
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sunday Service': return LucideIcons.church;
      case 'Bible Study': return LucideIcons.bookOpen;
      case 'Youth': return LucideIcons.users;
      case 'Prayer Meeting': return LucideIcons.heart;
      case 'Conference': return LucideIcons.presentation;
      case 'Special Event': return LucideIcons.sparkles;
      case 'Guest Speaker': return LucideIcons.mic2;
      default: return LucideIcons.folder;
    }
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
            // Premium Header with Logo
            _buildHeader(context, isDark),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildSearchBar(context, isDark),
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),

            // Content
            Expanded(
              child: BlocBuilder<SermonCubit, SermonState>(
                builder: (context, state) {
                  if (state is SermonLoading) {
                    return const VaultShimmer();
                  }

                  if (state is SermonError) {
                    return _buildErrorState(context, state, isDark);
                  }

                  if (state is SermonLoaded) {
                    if (_isSearching) {
                      return _buildSearchResults(context, state, isDark);
                    }
                    return _buildVaultContent(context, state, isDark);
                  }

                  return _buildEmptyState(context, isDark);
                },
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button
      floatingActionButton: _buildFAB(context, isDark),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                isDark
                    ? 'assets/icon/logo_darkBG.png'
                    : 'assets/icon/logo_lightBG.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.bookOpen,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sermon Vault',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  'Your Digital Sanctuary',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Sync Status
          SyncStatusIndicator(
            status: _syncStatus,
            onTap: () {
              HapticFeedback.selectionClick();
              _initializeSermons();
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(8) : Colors.transparent,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearch,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Search by verse, topic, or speaker...',
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

  Widget _buildVaultContent(BuildContext context, SermonLoaded state, bool isDark) {
    // Separate "All Sermons" and series folders
    final allSermons = state.folders.where((f) => f.isAllSermons).toList();
    final seriesFolders = state.folders
        .where((f) => !f.isAllSermons && f.id != 'uncategorized')
        .toList();
    final uncategorized = state.folders
        .where((f) => f.id == 'uncategorized')
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // "All Sermons" Card - Full width, special treatment
        if (allSermons.isNotEmpty) ...[
          _buildAllSermonsCard(allSermons.first, isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 24),
        ],

        // Series Section
        if (seriesFolders.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Series',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              TextButton.icon(
                onPressed: _createNewSeries,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('New'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 12),

          // 2-Column Grid for Series
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: seriesFolders.length,
            itemBuilder: (context, index) {
              return SeriesGridCard(
                folder: seriesFolders[index],
                isDark: isDark,
                onTap: () => _navigateToFolder(seriesFolders[index]),
                onLongPress: () => _showSeriesOptions(seriesFolders[index]),
              ).animate().fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: 350 + (index * 50)),
              ).scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
              );
            },
          ),
          const SizedBox(height: 24),
        ],

        // Uncategorized Section
        if (uncategorized.isNotEmpty) ...[
          Text(
            'Uncategorized',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
          const SizedBox(height: 12),
          _buildUncategorizedCard(uncategorized.first, isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: 550.ms),
        ],

        // Empty state hint
        if (seriesFolders.isEmpty && state.notes.isEmpty) ...[
          _buildEmptyHint(context, isDark)
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAllSermonsCard(SermonFolder folder, bool isDark) {
    return GestureDetector(
      onTap: () => _navigateToFolder(folder),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withAlpha(200),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.library,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Sermons',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${folder.noteCount} notes in your vault',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.chevronRight,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUncategorizedCard(SermonFolder folder, bool isDark) {
    return GestureDetector(
      onTap: () => _navigateToFolder(folder),
      onLongPress: () => _showUncategorizedOptions(folder, isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.inbox,
                color: Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Uncategorized',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            // Edit icon button
            GestureDetector(
              onTap: () => _showUncategorizedOptions(folder, isDark),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.moreHorizontal,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${folder.noteCount}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : Colors.black45,
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
      ),
    );
  }

  /// Show options for Uncategorized folder
  void _showUncategorizedOptions(SermonFolder folder, bool isDark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.inbox, color: Colors.grey),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uncategorized',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${folder.noteCount} notes without a series',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Create new series from uncategorized notes
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.folderPlus, color: AppTheme.primaryColor),
              ),
              title: const Text('Create Series from Notes'),
              subtitle: Text(
                'Move all ${folder.noteCount} notes to a new series',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateSeriesFromUncategorized(isDark, folder.noteCount);
              },
            ),

            // View and organize
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.layoutGrid, color: Colors.blue.shade400),
              ),
              title: const Text('View & Organize'),
              subtitle: Text(
                'Open folder to move notes individually',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToFolder(folder);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Create a new series and move all uncategorized notes to it
  void _showCreateSeriesFromUncategorized(bool isDark, int noteCount) {
    final controller = TextEditingController();
    String selectedColor = '#673AB7';
    String selectedIcon = 'folder';

    final colors = [
      '#673AB7', '#9C27B0', '#E91E63', '#F44336',
      '#FF9800', '#FFC107', '#4CAF50', '#009688',
      '#00BCD4', '#2196F3', '#3F51B5', '#607D8B',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(LucideIcons.folderPlus, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Text('New Series'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create a series and move all $noteCount uncategorized notes to it.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Series name',
                    filled: true,
                    fillColor: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(LucideIcons.folder),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                Text(
                  'Color',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(LucideIcons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter a series name'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);

                // Show loading
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Text('Creating "$name" and moving notes...'),
                      ],
                    ),
                    duration: const Duration(seconds: 10),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );

                // Create series
                final cubit = this.context.read<SermonCubit>();
                final newSeries = await cubit.createSeries(
                  title: name,
                  color: selectedColor,
                  icon: selectedIcon,
                );

                if (newSeries != null) {
                  // Move all uncategorized notes to the new series
                  final uncategorizedNotes = cubit.getNotesForFolder('uncategorized');
                  for (final note in uncategorizedNotes) {
                    await cubit.saveNote(note.copyWith(seriesId: newSeries.id));
                  }

                  // Refresh
                  await cubit.loadSermons();

                  if (mounted) {
                    ScaffoldMessenger.of(this.context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(LucideIcons.check, color: Colors.white, size: 18),
                            const SizedBox(width: 12),
                            Text('Created "$name" with $noteCount notes!'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(LucideIcons.folderPlus, size: 18),
              label: const Text('Create & Move'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryColor.withAlpha(15)
            : AppTheme.primaryColor.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(30),
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.sparkles,
            size: 48,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Start Your Spiritual Journey',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a series to organize your notes, or add your first sermon note to get started.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
              'Try searching by verse, topic, or speaker',
              style: GoogleFonts.inter(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];
        return _buildSearchResultTile(context, note, isDark)
            .animate()
            .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 50));
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
            color: Colors.black.withAlpha(isDark ? 40 : 10),
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
            color: AppTheme.primaryColor.withAlpha(20),
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
            if (note.verse != null && note.verse!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                note.verse!,
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

  Widget _buildErrorState(BuildContext context, SermonError state, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 56,
              color: Colors.red.withAlpha(180),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _initializeSermons,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Try Again'),
            ),
          ],
        ),
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.bookOpen,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Your Sermon Vault Awaits',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Capture sermon insights, organize them into series, and build your personal library of spiritual wisdom.',
              style: GoogleFonts.inter(
                fontSize: 15,
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
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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

  Widget _buildFAB(BuildContext context, bool isDark) {
    return FloatingActionButton.extended(
      onPressed: _createNewNote,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(LucideIcons.plus),
      label: Text(
        'New Note',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 600.ms).scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
    );
  }

  void _showSeriesOptions(SermonFolder folder) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
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
                folder.name,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(LucideIcons.pencil, color: AppTheme.primaryColor),
                title: const Text('Rename Series'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameSeriesDialog(folder, isDark);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.palette, color: Colors.orange.shade400),
                title: const Text('Change Color & Icon'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditSeriesDialog(folder, isDark);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.red),
                title: const Text('Delete Series', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteSeries(folder);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Quick rename dialog for series
  void _showRenameSeriesDialog(SermonFolder folder, bool isDark) {
    final controller = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.pencil, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Text('Rename Series'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Series name',
            filled: true,
            fillColor: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != folder.name && folder.id != null) {
                // Get the series and update it
                final cubit = context.read<SermonCubit>();
                final allSeries = cubit.getAllSeries();
                final series = allSeries.firstWhere(
                  (s) => s.id == folder.id,
                  orElse: () => allSeries.first,
                );

                await cubit.updateSeries(series.copyWith(title: newName));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Renamed to "$newName"'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  /// Full edit dialog for series (color & icon)
  void _showEditSeriesDialog(SermonFolder folder, bool isDark) {
    String selectedColor = folder.color;
    String selectedIcon = folder.icon;

    final colors = [
      '#673AB7', '#9C27B0', '#E91E63', '#F44336',
      '#FF9800', '#FFC107', '#4CAF50', '#009688',
      '#00BCD4', '#2196F3', '#3F51B5', '#607D8B',
    ];

    final icons = [
      'folder', 'book', 'bookmark', 'heart',
      'star', 'flame', 'cross', 'church',
      'bible', 'pray', 'dove', 'crown',
    ];

    IconData _getIcon(String name) {
      switch (name) {
        case 'book': return LucideIcons.book;
        case 'bookmark': return LucideIcons.bookmark;
        case 'heart': return LucideIcons.heart;
        case 'star': return LucideIcons.star;
        case 'flame': return LucideIcons.flame;
        case 'cross': return LucideIcons.cross;
        case 'church': return LucideIcons.church;
        case 'bible': return LucideIcons.bookOpen;
        case 'pray': return LucideIcons.heart;
        case 'dove': return LucideIcons.bird;
        case 'crown': return LucideIcons.crown;
        default: return LucideIcons.folder;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(LucideIcons.palette, color: Colors.orange.shade400),
              const SizedBox(width: 12),
              const Text('Customize Series'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: Colors.black26, blurRadius: 8)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(LucideIcons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Icon',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((icon) {
                    final isSelected = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(int.parse(selectedColor.replaceFirst('#', '0xFF')))
                              : (isDark ? Colors.white.withAlpha(15) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getIcon(icon),
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.black45),
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (folder.id != null) {
                  final cubit = context.read<SermonCubit>();
                  final allSeries = cubit.getAllSeries();
                  final series = allSeries.firstWhere(
                    (s) => s.id == folder.id,
                    orElse: () => allSeries.first,
                  );

                  await cubit.updateSeries(series.copyWith(
                    color: selectedColor,
                    icon: selectedIcon,
                  ));

                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: const Text('Series updated!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSeries(SermonFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Series'),
        content: Text('Delete "${folder.name}"? Notes will be moved to Uncategorized.'),
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
    );

    if (confirmed == true && folder.id != null && mounted) {
      await context.read<SermonCubit>().deleteSeries(folder.id!);
    }
  }
}
