import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/testimony/domain/entities/testimony.dart';
import 'package:quick_church/features/testimony/presentation/bloc/testimony_cubit.dart';
import 'package:quick_church/features/testimony/presentation/bloc/testimony_state.dart';
import 'package:quick_church/injection.dart';
import 'package:share_plus/share_plus.dart';

/// Testimony Vault - View all testimonies, answered prayers, and gratitude entries.
class TestimonyVaultPage extends StatefulWidget {
  const TestimonyVaultPage({super.key});

  @override
  State<TestimonyVaultPage> createState() => _TestimonyVaultPageState();
}

class _TestimonyVaultPageState extends State<TestimonyVaultPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => getIt<TestimonyCubit>()..loadData(),
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(
          title: const Text('Testimony Vault'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Answered'),
              Tab(text: 'Testimonies'),
              Tab(text: 'Gratitude'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.plus),
              onPressed: () => _showAddOptions(context),
              tooltip: 'Add Entry',
            ),
          ],
        ),
        body: BlocConsumer<TestimonyCubit, TestimonyState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<TestimonyCubit>().clearError();
            }
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppTheme.answeredColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<TestimonyCubit>().clearMessage();
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allTestimonies = state.testimonies;
            final answeredPrayer = state.answeredPrayerTestimonies;
            final standalone = state.standaloneTestimonies;
            final gratitude = state.gratitudeEntries;
            final stats = state.stats;

            return Column(
              children: [
                // Stats Header
                _buildStatsHeader(
                  context,
                  isDark,
                  stats: stats,
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // All
                      _buildTestimonyList(context, isDark, allTestimonies),
                      // Answered Prayers
                      _buildTestimonyList(
                        context,
                        isDark,
                        answeredPrayer,
                        emptyMessage: 'No answered prayer testimonies yet.\nMark prayers as answered in the Prayer tab!',
                        emptyIcon: LucideIcons.checkCircle,
                      ),
                      // Standalone Testimonies
                      _buildTestimonyList(
                        context,
                        isDark,
                        standalone,
                        emptyMessage: 'No testimonies yet.\nShare your story of God\'s faithfulness!',
                        emptyIcon: LucideIcons.sparkles,
                      ),
                      // Gratitude
                      _buildTestimonyList(
                        context,
                        isDark,
                        gratitude,
                        emptyMessage: 'No gratitude entries yet.\nStart recording what you\'re thankful for!',
                        emptyIcon: LucideIcons.heart,
                        showGratitudeButton: true,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddOptions(context),
          icon: const Icon(LucideIcons.plus),
          label: const Text('Add'),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(
    BuildContext context,
    bool isDark, {
    required TestimonyStats stats,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.answeredColor.withOpacity(0.15),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.answeredColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, '${stats.totalTestimonies}', 'Total'),
          _buildStatDivider(isDark),
          _buildStatItem(context, '${stats.gratitudeCount}', 'Gratitude'),
          _buildStatDivider(isDark),
          _buildStatItem(context, '${stats.gratitudeStreak}', 'Streak'),
          _buildStatDivider(isDark),
          _buildStatItem(context, '${stats.publicCount}', 'Shared'),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.answeredColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white54
                : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }

  Widget _buildTestimonyList(
    BuildContext context,
    bool isDark,
    List<Testimony> testimonies, {
    String? emptyMessage,
    IconData? emptyIcon,
    bool showGratitudeButton = false,
  }) {
    if (testimonies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon ?? LucideIcons.bookMarked,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage ?? 'No entries yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            if (showGratitudeButton) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _showAddGratitude(context),
                icon: const Icon(LucideIcons.plus),
                label: const Text('Add Gratitude'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: testimonies.length,
      itemBuilder: (context, index) {
        final testimony = testimonies[index];
        return _buildTestimonyCard(context, isDark, testimony);
      },
    );
  }

  Widget _buildTestimonyCard(BuildContext context, bool isDark, Testimony testimony) {
    final icon = _getTypeIcon(testimony.type);
    final color = _getTypeColor(testimony.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTestimonyDetail(context, testimony),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testimony.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              testimony.type.displayName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color,
                              ),
                            ),
                            if (testimony.isAnsweredPrayer && testimony.prayerCount > 0) ...[
                              const SizedBox(width: 8),
                              Icon(
                                LucideIcons.flame,
                                size: 12,
                                color: AppTheme.goldenPromise,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Prayed ${testimony.prayerCount}x',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.goldenPromise,
                                ),
                              ),
                            ],
                            if (testimony.isGratitude && testimony.category != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  testimony.category!.displayName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.pink,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Privacy badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: testimony.isPublic
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          testimony.isPublic ? LucideIcons.globe : LucideIcons.lock,
                          size: 12,
                          color: testimony.isPublic
                              ? AppTheme.primaryColor
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          testimony.isPublic ? 'Public' : 'Private',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: testimony.isPublic
                                ? AppTheme.primaryColor
                                : (isDark ? Colors.white38 : Colors.black38),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Story Preview
              if (testimony.story != null && testimony.story!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  testimony.story!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Footer
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    testimony.timeAgo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  if (testimony.celebrationCount > 0) ...[
                    const Spacer(),
                    Icon(
                      LucideIcons.partyPopper,
                      size: 14,
                      color: AppTheme.goldenPromise,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${testimony.celebrationCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.goldenPromise,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(TestimonyType type) {
    switch (type) {
      case TestimonyType.standalone:
        return LucideIcons.sparkles;
      case TestimonyType.gratitude:
        return LucideIcons.heart;
      case TestimonyType.answeredPrayer:
        return LucideIcons.checkCircle;
    }
  }

  Color _getTypeColor(TestimonyType type) {
    switch (type) {
      case TestimonyType.standalone:
        return AppTheme.answeredColor;
      case TestimonyType.gratitude:
        return Colors.pink;
      case TestimonyType.answeredPrayer:
        return AppTheme.answeredColor;
    }
  }

  void _showAddOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            const SizedBox(height: 24),
            Text(
              'Add Entry',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.answeredColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.sparkles, color: AppTheme.answeredColor),
              ),
              title: const Text('Standalone Testimony'),
              subtitle: const Text('Share a story of God\'s faithfulness'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddTestimony(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.heart, color: Colors.pink),
              ),
              title: const Text('Gratitude Entry'),
              subtitle: const Text('Record what you\'re thankful for'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddGratitude(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddTestimony(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddTestimonySheet(
        onSave: (title, story, isPublic) {
          context.read<TestimonyCubit>().createTestimony(
            title: title,
            story: story,
            isPublic: isPublic,
          );
        },
      ),
    );
  }

  void _showAddGratitude(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddGratitudeSheet(
        onSave: (title, story, category, isPublic) {
          context.read<TestimonyCubit>().createGratitude(
            title: title,
            story: story,
            category: category,
            isPublic: isPublic,
          );
        },
      ),
    );
  }

  void _showTestimonyDetail(BuildContext context, Testimony testimony) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getTypeColor(testimony.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTypeIcon(testimony.type),
                            color: color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                testimony.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                testimony.type.displayName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Row for answered prayer
                    if (testimony.isAnsweredPrayer) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDetailStat(context, '${testimony.prayerCount}x', 'Prayed'),
                            _buildDetailStat(
                              context,
                              testimony.daysToAnswer != null ? '${testimony.daysToAnswer}d' : '-',
                              'Wait Time',
                            ),
                            _buildDetailStat(
                              context,
                              '${testimony.celebrationCount}',
                              'Celebrated',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Category for gratitude
                    if (testimony.isGratitude && testimony.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.tag, size: 16, color: Colors.pink),
                            const SizedBox(width: 8),
                            Text(
                              testimony.category!.displayName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.pink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Story
                    if (testimony.story != null && testimony.story!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.quote, size: 18, color: color),
                                const SizedBox(width: 8),
                                Text(
                                  'My Story',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              testimony.story!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Date
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(testimony.eventDate ?? testimony.createdAt),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.read<TestimonyCubit>().togglePrivacy(testimony.id);
                            },
                            icon: Icon(
                              testimony.isPublic ? LucideIcons.lock : LucideIcons.globe,
                              size: 18,
                            ),
                            label: Text(testimony.isPublic ? 'Make Private' : 'Share Publicly'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _shareTestimony(testimony),
                            icon: const Icon(LucideIcons.share2, size: 18),
                            label: const Text('Share'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Delete option
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDelete(context, testimony);
                      },
                      icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
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

  Widget _buildDetailStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white54
                : Colors.black54,
          ),
        ),
      ],
    );
  }

  void _shareTestimony(Testimony testimony) {
    final text = '''
${testimony.title}

${testimony.story ?? ''}

${testimony.isAnsweredPrayer && testimony.prayerCount > 0 ? 'Prayed ${testimony.prayerCount} times before God answered!' : ''}

Shared via Kneel - Your Prayer Companion
''';
    Share.share(text);
  }

  void _confirmDelete(BuildContext context, Testimony testimony) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
          'Are you sure you want to delete "${testimony.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TestimonyCubit>().deleteTestimony(testimony.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ============================================================================
// Add Testimony Sheet
// ============================================================================

class _AddTestimonySheet extends StatefulWidget {
  final Function(String title, String story, bool isPublic) onSave;

  const _AddTestimonySheet({required this.onSave});

  @override
  State<_AddTestimonySheet> createState() => _AddTestimonySheetState();
}

class _AddTestimonySheetState extends State<_AddTestimonySheet> {
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  bool _isPublic = false;

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.answeredColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.sparkles, color: AppTheme.answeredColor),
                ),
                const SizedBox(width: 12),
                Text(
                  'Share Your Testimony',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Share a story of God\'s faithfulness in your life',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Give your testimony a title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _storyController,
              decoration: const InputDecoration(
                labelText: 'Your Story',
                hintText: 'What happened? How did God work in your life?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              title: const Text('Share with Community'),
              subtitle: const Text('Others can see and be encouraged by your story'),
              secondary: Icon(
                _isPublic ? LucideIcons.globe : LucideIcons.lock,
                color: _isPublic ? AppTheme.primaryColor : null,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final story = _storyController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a title'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      widget.onSave(title, story, _isPublic);
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();
                    },
                    child: const Text('Save Testimony'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Add Gratitude Sheet
// ============================================================================

class _AddGratitudeSheet extends StatefulWidget {
  final Function(String title, String? story, GratitudeCategory? category, bool isPublic) onSave;

  const _AddGratitudeSheet({required this.onSave});

  @override
  State<_AddGratitudeSheet> createState() => _AddGratitudeSheetState();
}

class _AddGratitudeSheetState extends State<_AddGratitudeSheet> {
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  GratitudeCategory? _category;
  bool _isPublic = false;

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.heart, color: Colors.pink),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gratitude Entry',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'What are you thankful for today?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'I\'m grateful for...',
                hintText: 'e.g., My family\'s health',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GratitudeCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
              ),
              items: GratitudeCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.displayName),
                );
              }).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _storyController,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Why are you grateful for this?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              title: const Text('Share with Community'),
              subtitle: const Text('Inspire others with your gratitude'),
              secondary: Icon(
                _isPublic ? LucideIcons.globe : LucideIcons.lock,
                color: _isPublic ? AppTheme.primaryColor : null,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final story = _storyController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter what you\'re grateful for'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      widget.onSave(
                        title,
                        story.isEmpty ? null : story,
                        _category,
                        _isPublic,
                      );
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();
                    },
                    icon: const Icon(LucideIcons.heart, size: 18),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
