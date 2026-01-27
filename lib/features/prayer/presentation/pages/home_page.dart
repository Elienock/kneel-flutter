import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/guided/data/mock_guided_content.dart';
import 'package:quick_church/features/guided/presentation/pages/guided_sessions_page.dart';
import 'package:quick_church/features/guided/presentation/widgets/guided_session_card.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'package:quick_church/features/prayer/presentation/pages/about_page.dart';
import 'package:quick_church/features/prayer/presentation/widgets/daily_verse_card.dart';
import 'package:quick_church/features/prayer/presentation/widgets/prayer_detail_sheet.dart';

/// Home tab displaying daily verse, streak summary, and recent prayers.
class HomePage extends StatelessWidget {
  final VoidCallback? onNavigateToPrayers;

  const HomePage({super.key, this.onNavigateToPrayers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: BlocBuilder<PrayerCubit, PrayerState>(
          builder: (context, state) {
            final prayers = state is PrayerLoaded ? state.prayers : <Prayer>[];

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                  title: Text(
                    'Kneel',
                    style: theme.textTheme.displayMedium,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(LucideIcons.settings),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      ),
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Daily Verse Header
                      const DailyVerseCard(),
                      const SizedBox(height: 24),

                      // Streak Summary Card
                      _StreakSummaryCard(prayers: prayers),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _QuickActionsRow(prayers: prayers),
                      const SizedBox(height: 24),

                      // Guided Sessions Section
                      _GuidedSessionsSection(),
                      const SizedBox(height: 24),

                      // Recent Prayers Section
                      _RecentPrayersSection(
                        prayers: prayers,
                        onSeeAll: onNavigateToPrayers,
                      ),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Streak summary card showing prayer consistency.
class _StreakSummaryCard extends StatelessWidget {
  final List<Prayer> prayers;

  const _StreakSummaryCard({required this.prayers});

  int _calculateStreak() {
    if (prayers.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get unique days with prayer activity
    final prayerDays = <DateTime>{};
    for (final prayer in prayers) {
      final createdDay = DateTime(
        prayer.createdAt.year,
        prayer.createdAt.month,
        prayer.createdAt.day,
      );
      prayerDays.add(createdDay);

      if (prayer.lastPrayedAt != null) {
        final prayedDay = DateTime(
          prayer.lastPrayedAt!.year,
          prayer.lastPrayedAt!.month,
          prayer.lastPrayedAt!.day,
        );
        prayerDays.add(prayedDay);
      }
    }

    // Calculate consecutive days from today backwards
    int streak = 0;
    var checkDate = today;

    while (prayerDays.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // If no activity today, check if yesterday was active
    if (streak == 0 && prayerDays.contains(today.subtract(const Duration(days: 1)))) {
      checkDate = today.subtract(const Duration(days: 1));
      while (prayerDays.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final streak = _calculateStreak();
    final totalPrayers = prayers.fold<int>(0, (sum, p) => sum + p.prayerCount);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA500).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.flame,
                  color: Color(0xFFFFA500),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prayer Streak',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Keep your prayer habit going',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: streak.toString(),
                  label: 'Day Streak',
                  icon: LucideIcons.flame,
                  color: const Color(0xFFFFA500),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatItem(
                  value: totalPrayers.toString(),
                  label: 'Times Prayed',
                  icon: LucideIcons.checkCircle,
                  color: AppTheme.answeredColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatItem(
                  value: prayers.where((p) => p.status == PrayerStatus.answered).length.toString(),
                  label: 'Answered',
                  icon: LucideIcons.sparkles,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual stat item in the streak card.
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Quick action buttons row.
class _QuickActionsRow extends StatelessWidget {
  final List<Prayer> prayers;

  const _QuickActionsRow({required this.prayers});

  @override
  Widget build(BuildContext context) {
    final activePrayers = prayers.where((p) => p.status == PrayerStatus.active).length;
    final urgentPrayers = prayers.where((p) => p.priority == PrayerPriority.urgent).length;

    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: LucideIcons.handMetal,
            label: 'Active',
            value: activePrayers.toString(),
            color: AppTheme.mediumColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: LucideIcons.alertTriangle,
            label: 'Urgent',
            value: urgentPrayers.toString(),
            color: AppTheme.urgentColor,
          ),
        ),
      ],
    );
  }
}

/// Quick action card widget.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Guided sessions horizontal scrolling section.
class _GuidedSessionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = MockGuidedContent.getFeatured();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Guided Sessions',
              style: theme.textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GuidedSessionsPage(),
                  ),
                );
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < sessions.length - 1 ? 12 : 0),
                child: GuidedSessionCard(
                  session: sessions[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GuidedSessionsPage(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Recent prayers section.
class _RecentPrayersSection extends StatelessWidget {
  final List<Prayer> prayers;
  final VoidCallback? onSeeAll;

  const _RecentPrayersSection({
    required this.prayers,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final recentPrayers = prayers
        .where((p) => p.status == PrayerStatus.active)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final displayPrayers = recentPrayers.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Prayers',
              style: theme.textTheme.titleLarge,
            ),
            if (recentPrayers.isNotEmpty)
              TextButton(
                onPressed: onSeeAll,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayPrayers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
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
            child: Column(
              children: [
                Icon(
                  LucideIcons.handMetal,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'No prayers yet',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your first prayer request',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          ...displayPrayers.map((prayer) => _RecentPrayerCard(
                prayer: prayer,
                onTap: () => PrayerDetailSheet.show(context, prayer),
              )),
      ],
    );
  }
}

/// Recent prayer card widget.
class _RecentPrayerCard extends StatefulWidget {
  final Prayer prayer;
  final VoidCallback onTap;

  const _RecentPrayerCard({
    required this.prayer,
    required this.onTap,
  });

  @override
  State<_RecentPrayerCard> createState() => _RecentPrayerCardState();
}

class _RecentPrayerCardState extends State<_RecentPrayerCard> {
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

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.prayer.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.prayer.isLocked)
                        const Icon(LucideIcons.lock, size: 16, color: Color(0xFF673AB7)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.prayer.isLocked ? 'Tap to unlock' : widget.prayer.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: widget.prayer.isLocked ? FontStyle.italic : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _prayedToday ? LucideIcons.checkCircle2 : LucideIcons.circle,
                size: 24,
                color: _prayedToday ? AppTheme.secondaryColor : theme.colorScheme.outline,
              ),
              onPressed: _prayedToday ? null : _recordPrayer,
            ),
          ],
        ),
      ),
    );
  }
}
