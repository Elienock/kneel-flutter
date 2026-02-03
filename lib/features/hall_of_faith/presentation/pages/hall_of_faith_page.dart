import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'package:quick_church/features/hall_of_faith/presentation/widgets/testimony_card.dart';
import 'package:quick_church/features/hall_of_faith/presentation/widgets/testimony_detail_view.dart';

/// Hall of Faith - A beautiful gallery of answered prayers and testimonies.
/// Features a masonry grid layout inspired by Pinterest, with gold accents
/// to celebrate each victory.
class HallOfFaithPage extends StatefulWidget {
  const HallOfFaithPage({super.key});

  @override
  State<HallOfFaithPage> createState() => _HallOfFaithPageState();
}

class _HallOfFaithPageState extends State<HallOfFaithPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom app bar with gold accent
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(isDark),
            ),
            title: Text(
              'Hall of Faith',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.search, size: 22),
                onPressed: () => _showSearchSheet(context),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          BlocBuilder<PrayerCubit, PrayerState>(
            builder: (context, state) {
              if (state is PrayerLoading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is PrayerError) {
                return SliverFillRemaining(
                  child: _buildErrorState(state.message, isDark),
                );
              }

              if (state is PrayerLoaded) {
                // Filter for answered prayers only
                var answeredPrayers = state.prayers
                    .where((p) => p.status == PrayerStatus.answered)
                    .toList();

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  answeredPrayers = answeredPrayers.where((p) {
                    return p.title.toLowerCase().contains(query) ||
                        (p.testimony?.toLowerCase().contains(query) ?? false) ||
                        p.tags.any((tag) => tag.toLowerCase().contains(query));
                  }).toList();
                }

                // Sort by answered date (most recent first)
                answeredPrayers.sort((a, b) {
                  final aDate = a.answeredAt ?? a.createdAt;
                  final bDate = b.answeredAt ?? b.createdAt;
                  return bDate.compareTo(aDate);
                });

                if (answeredPrayers.isEmpty) {
                  return SliverFillRemaining(
                    child: _searchQuery.isNotEmpty
                        ? _buildNoResultsState(isDark)
                        : _buildEmptyState(isDark),
                  );
                }

                return _buildMasonryGrid(answeredPrayers, isDark);
              }

              return SliverFillRemaining(
                child: _buildEmptyState(isDark),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.goldenPromise.withAlpha(isDark ? 30 : 20),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.goldenPromise.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  LucideIcons.trophy,
                  size: 24,
                  color: AppTheme.goldenPromise,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Your Victories',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.goldenPromise,
                      ),
                    ),
                    Text(
                      'Stones of Remembrance',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasonryGrid(List<Prayer> prayers, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childCount: prayers.length,
        itemBuilder: (context, index) {
          final prayer = prayers[index];
          return TestimonyCard(
            prayer: prayer,
            index: index,
            onTap: () => _openTestimonyDetail(prayer),
          );
        },
      ),
    );
  }

  void _openTestimonyDetail(Prayer prayer) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return TestimonyDetailView(
            prayer: prayer,
            onPublicToggle: (isPublic) {
              // TODO: Update prayer's isPublicTestimony
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Beautiful illustration placeholder
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.goldenPromise.withAlpha(30),
                    AppTheme.primaryColor.withAlpha(20),
                  ],
                ),
                borderRadius: BorderRadius.circular(80),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.goldenPromise.withAlpha(20),
                      borderRadius: BorderRadius.circular(60),
                    ),
                  ),
                  // Inner circle
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurface
                          : Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: AppTheme.goldenPromise.withAlpha(60),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.trophy,
                      size: 36,
                      color: AppTheme.goldenPromise,
                    ),
                  ),
                ],
              ),
            )
                .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.0, 1.0),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 32),

            Text(
              'Your miracles belong here',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Mark a prayer as answered to start\nyour Hall of Faith.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.white54 : Colors.black45,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Scripture reference
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(8)
                    : AppTheme.goldenPromise.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.goldenPromise.withAlpha(30),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '"Then Samuel took a stone and set it up..."',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '— 1 Samuel 7:12',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.goldenPromise,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 48,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No testimonies found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load testimonies',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<PrayerCubit>().loadPrayers(),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
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
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Search Testimonies',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by title, tag, or content...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                              Navigator.pop(context);
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  onSubmitted: (_) => Navigator.pop(context),
                ),
                const SizedBox(height: 16),

                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Search'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Hall of Faith content widget that can be embedded in other pages (e.g., tabs).
/// This is a simpler version without its own AppBar.
class HallOfFaithContent extends StatefulWidget {
  final List<Prayer> prayers;

  const HallOfFaithContent({
    super.key,
    required this.prayers,
  });

  @override
  State<HallOfFaithContent> createState() => _HallOfFaithContentState();
}

class _HallOfFaithContentState extends State<HallOfFaithContent> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort by answered date (most recent first)
    final sortedPrayers = List<Prayer>.from(widget.prayers)..sort((a, b) {
      final aDate = a.answeredAt ?? a.createdAt;
      final bDate = b.answeredAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    return CustomScrollView(
      slivers: [
        // Header with victory count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldenPromise.withAlpha(isDark ? 30 : 20),
                    AppTheme.goldenPromise.withAlpha(isDark ? 15 : 10),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.goldenPromise.withAlpha(40),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.goldenPromise.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.trophy,
                      size: 24,
                      color: AppTheme.goldenPromise,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${sortedPrayers.length} ${sortedPrayers.length == 1 ? 'Victory' : 'Victories'}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.goldenPromise,
                          ),
                        ),
                        Text(
                          'Stones of Remembrance',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Masonry grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: sortedPrayers.length,
            itemBuilder: (context, index) {
              final prayer = sortedPrayers[index];
              return TestimonyCard(
                prayer: prayer,
                index: index,
                onTap: () => _openTestimonyDetail(prayer),
              );
            },
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  void _openTestimonyDetail(Prayer prayer) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return TestimonyDetailView(
            prayer: prayer,
            onPublicToggle: (isPublic) {
              // TODO: Update prayer's isPublicTestimony
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}

/// Celebration overlay shown when a prayer is marked as answered.
class HallOfFaithCelebration extends StatelessWidget {
  final Prayer prayer;
  final VoidCallback onComplete;

  const HallOfFaithCelebration({
    super.key,
    required this.prayer,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss after animation
    Future.delayed(const Duration(seconds: 3), onComplete);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated trophy
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.goldenPromise.withAlpha(30),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  LucideIcons.trophy,
                  size: 50,
                  color: AppTheme.goldenPromise,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .then()
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 1000.ms,
                  ),

              const SizedBox(height: 32),

              Text(
                'Victory!',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.goldenPromise,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 200.ms,
                    duration: 400.ms,
                  ),

              const SizedBox(height: 12),

              Text(
                'Prayer answered!',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  prayer.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              ),

              const SizedBox(height: 32),

              Text(
                'Added to your Hall of Faith',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
