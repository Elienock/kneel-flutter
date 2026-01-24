import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'package:quick_church/features/prayer/presentation/widgets/add_prayer_bottom_sheet.dart';
import 'package:quick_church/features/prayer/presentation/widgets/prayer_detail_sheet.dart';

/// Prayers tab showing the full categorized list of prayer requests.
class PrayersPage extends StatefulWidget {
  const PrayersPage({super.key});

  @override
  State<PrayersPage> createState() => _PrayersPageState();
}

class _PrayersPageState extends State<PrayersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<_CategoryFilter> _categories = [
    const _CategoryFilter('all', 'All', LucideIcons.layoutGrid),
    const _CategoryFilter('personal', 'Personal', LucideIcons.user),
    const _CategoryFilter('family', 'Family', LucideIcons.users),
    const _CategoryFilter('health', 'Health', LucideIcons.heartPulse),
    const _CategoryFilter('work', 'Work', LucideIcons.briefcase),
    const _CategoryFilter('church', 'Church', LucideIcons.church),
    const _CategoryFilter('urgent', 'Urgent', LucideIcons.alertTriangle),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search prayers...',
                        border: InputBorder.none,
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      style: theme.textTheme.bodyLarge,
                      onChanged: (value) => setState(() => _searchQuery = value),
                    )
                  : Text(
                      'Prayers',
                      style: theme.textTheme.displayMedium,
                    ),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = '';
                        _searchController.clear();
                      }
                    });
                  },
                ),
                if (!_isSearching)
                  IconButton(
                    icon: Icon(LucideIcons.slidersHorizontal),
                    onPressed: () => _showFilterDialog(context),
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Column(
                  children: [
                    // Category filter chips
                    _buildCategoryFilters(context),
                    const SizedBox(height: 8),
                    // Tab bar for Active/All
                    TabBar(
                      controller: _tabController,
                      labelColor: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      unselectedLabelColor: const Color(0xFF8E8E93),
                      indicatorColor: AppTheme.primaryColor,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Active'),
                        Tab(text: 'All'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: BlocConsumer<PrayerCubit, PrayerState>(
            listener: (context, state) {
              if (state is PrayerLoaded && state.successMessage != null) {
                _showSnackBar(context, state.successMessage!);
                context.read<PrayerCubit>().clearMessage();
              }
            },
            builder: (context, state) {
              if (state is PrayerLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final prayers = state is PrayerLoaded ? state.prayers : <Prayer>[];

              return TabBarView(
                controller: _tabController,
                children: [
                  // Active prayers
                  _buildPrayerList(
                    context,
                    prayers.where((p) => p.status == PrayerStatus.active).toList(),
                  ),
                  // All prayers
                  _buildPrayerList(context, prayers),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category.id;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
                    : (isDark ? AppTheme.darkSurface : AppTheme.cardBackground),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0xFFE5E5EA),
                      ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected
                        ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
                        : const Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
                          : (isDark ? Colors.white : const Color(0xFF1C1C1E)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrayerList(BuildContext context, List<Prayer> prayers) {
    final theme = Theme.of(context);

    // Filter by category
    var filteredPrayers = prayers;
    if (_selectedCategory != 'all') {
      filteredPrayers = prayers
          .where((p) => p.tags.contains(_selectedCategory))
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      filteredPrayers = filteredPrayers.where((p) {
        return p.title.toLowerCase().contains(lowerQuery) ||
            p.description.toLowerCase().contains(lowerQuery) ||
            p.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
            (p.requesterName?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }

    // Sort by priority (urgent first) then by date
    filteredPrayers.sort((a, b) {
      if (a.priority == PrayerPriority.urgent && b.priority != PrayerPriority.urgent) {
        return -1;
      }
      if (b.priority == PrayerPriority.urgent && a.priority != PrayerPriority.urgent) {
        return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    if (filteredPrayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.handMetal,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No prayers in this category',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a new prayer request',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => AddPrayerBottomSheet.show(context),
              icon: Icon(LucideIcons.plus),
              label: const Text('Add Prayer'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PrayerCubit>().loadPrayers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPrayers.length,
        itemBuilder: (context, index) {
          final prayer = filteredPrayers[index];
          return _PrayerListItem(
            prayer: prayer,
            onTap: () => _showPrayerDetail(context, prayer),
            onDismissed: () => context.read<PrayerCubit>().deletePrayer(prayer.id),
          );
        },
      ),
    );
  }

  void _showPrayerDetail(BuildContext context, Prayer prayer) {
    PrayerDetailSheet.show(context, prayer);
  }

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withAlpha(77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Filter Prayers', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Priority', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PrayerPriority.values.map((priority) {
                return FilterChip(
                  label: Text(priority.name.toUpperCase()),
                  selected: false,
                  onSelected: (selected) {
                    Navigator.pop(context);
                    setState(() => _selectedCategory = priority.name);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Status', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Active'),
                  selected: false,
                  onSelected: (selected) {
                    Navigator.pop(context);
                    _tabController.animateTo(0);
                  },
                ),
                FilterChip(
                  label: const Text('Answered'),
                  selected: false,
                  onSelected: (selected) {
                    Navigator.pop(context);
                    _tabController.animateTo(1);
                    setState(() => _selectedCategory = 'answered');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _selectedCategory = 'all');
                },
                child: const Text('Clear Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Category filter data class.
class _CategoryFilter {
  final String id;
  final String label;
  final IconData icon;

  const _CategoryFilter(this.id, this.label, this.icon);
}

/// Prayer list item widget.
class _PrayerListItem extends StatefulWidget {
  final Prayer prayer;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _PrayerListItem({
    required this.prayer,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  State<_PrayerListItem> createState() => _PrayerListItemState();
}

class _PrayerListItemState extends State<_PrayerListItem> {
  bool _prayedToday = false;

  @override
  void initState() {
    super.initState();
    _checkIfPrayedToday();
  }

  void _checkIfPrayedToday() {
    if (widget.prayer.lastPrayedAt != null) {
      final now = DateTime.now();
      final lastPrayed = widget.prayer.lastPrayedAt!;
      _prayedToday = now.year == lastPrayed.year &&
          now.month == lastPrayed.month &&
          now.day == lastPrayed.day;
    }
  }

  void _recordPrayer() {
    HapticFeedback.lightImpact();
    context.read<PrayerCubit>().incrementPrayerCount(widget.prayer.id);
    setState(() => _prayedToday = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Amen. Your prayer has been recorded.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final priorityColor = switch (widget.prayer.priority) {
      PrayerPriority.urgent => AppTheme.urgentColor,
      PrayerPriority.high => AppTheme.highColor,
      PrayerPriority.medium => AppTheme.mediumColor,
      PrayerPriority.low => AppTheme.lowColor,
    };

    final isAnswered = widget.prayer.status == PrayerStatus.answered;

    return Dismissible(
      key: Key(widget.prayer.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.urgentColor,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        child: Icon(LucideIcons.trash2, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 77 : 13),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Priority indicator
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: isAnswered ? AppTheme.answeredColor : priorityColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16).copyWith(left: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isAnswered)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.answeredColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ANSWERED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.answeredColor,
                                    ),
                                  ),
                                ),
                              if (widget.prayer.priority == PrayerPriority.urgent)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.urgentColor.withAlpha(26),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'URGENT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.urgentColor,
                                    ),
                                  ),
                                ),
                              if (widget.prayer.isLocked)
                                Icon(
                                  LucideIcons.lock,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                            ],
                          ),
                          if (isAnswered || widget.prayer.priority == PrayerPriority.urgent || widget.prayer.isLocked)
                            const SizedBox(height: 6),
                          Text(
                            widget.prayer.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: isAnswered
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.prayer.isLocked ? 'Tap to unlock' : widget.prayer.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: widget.prayer.isLocked ? FontStyle.italic : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.checkCircle,
                                size: 14,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.prayer.prayerCount} prayers',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                LucideIcons.clock,
                                size: 14,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(widget.prayer.createdAt),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            _prayedToday ? LucideIcons.checkCircle2 : LucideIcons.circle,
                            color: _prayedToday ? AppTheme.secondaryColor : theme.colorScheme.outline,
                          ),
                          onPressed: _prayedToday ? null : _recordPrayer,
                        ),
                      ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
