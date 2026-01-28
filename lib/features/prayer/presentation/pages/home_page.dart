import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/guided/data/mock_guided_content.dart';
import 'package:quick_church/features/guided/presentation/pages/guided_sessions_page.dart';
import 'package:quick_church/features/guided/presentation/widgets/guided_session_card.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'package:quick_church/features/prayer/presentation/widgets/daily_verse_card.dart';
import 'package:quick_church/features/prayer/presentation/widgets/prayer_detail_sheet.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';
import 'package:quick_church/features/profile/presentation/pages/profile_page.dart';
import 'package:quick_church/features/profile/presentation/widgets/email_verification_banner.dart';

/// Home tab with YouVersion-style dual-view: Today and Community.
class HomePage extends StatelessWidget {
  final VoidCallback? onNavigateToPrayers;

  const HomePage({super.key, this.onNavigateToPrayers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Header with profile and tabs on same line
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                child: Row(
                  children: [
                    // Profile Avatar with CachedNetworkImage
                    BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, profileState) {
                        String? photoUrl;
                        String displayName = 'U';

                        if (profileState is ProfileLoaded) {
                          photoUrl = profileState.profile.photoUrl;
                          displayName = profileState.profile.displayName;
                        }

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfilePage()),
                          ),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: photoUrl != null && photoUrl.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      width: 36,
                                      height: 36,
                                      placeholder: (_, __) => Center(
                                        child: Text(
                                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => const Center(
                                        child: Icon(
                                          LucideIcons.user,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    // Tab Bar
                    Expanded(
                      child: _HomeTabBar(isDark: isDark),
                    ),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  children: [
                    _TodayView(onNavigateToPrayers: onNavigateToPrayers),
                    const _CommunityView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple TabBar with underline indicator.
class _HomeTabBar extends StatelessWidget {
  final bool isDark;

  const _HomeTabBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: AppTheme.primaryColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelColor: isDark ? Colors.white : Colors.black,
      unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
      labelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      tabs: const [
        Tab(text: 'Today'),
        Tab(text: 'Community'),
      ],
    );
  }
}

/// Time-based greeting widget using ProfileCubit for user data.
class _GreetingWidget extends StatelessWidget {
  const _GreetingWidget();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String userName = 'Friend';

        if (state is ProfileLoaded) {
          userName = state.profile.displayName.split(' ').first;
        } else if (state is ProfileNeedsOnboarding) {
          userName = state.profile.displayName.split(' ').first;
        }

        return Text(
          '${_getGreeting()}, $userName',
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        );
      },
    );
  }
}

/// Today View - Daily verse, streaks, quick actions, guided sessions, recent prayers.
class _TodayView extends StatelessWidget {
  final VoidCallback? onNavigateToPrayers;

  const _TodayView({this.onNavigateToPrayers});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerCubit, PrayerState>(
      builder: (context, state) {
        final prayers = state is PrayerLoaded ? state.prayers : <Prayer>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Email Verification Banner (only for unverified email users)
            const EmailVerificationBanner(),

            // Time-based Greeting
            const _GreetingWidget(),
            const SizedBox(height: 20),

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
          ],
        );
      },
    );
  }
}

/// Community View - Friend activity feed and shared prayer intentions.
class _CommunityView extends StatelessWidget {
  const _CommunityView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Friends Activity Header
        const _SectionHeader(
          title: 'Friend Activity',
          icon: LucideIcons.activity,
        ),
        const SizedBox(height: 12),

        // Activity Feed
        ..._mockFriendActivities.map((activity) => _FriendActivityCard(
              activity: activity,
              isDark: isDark,
            )),

        const SizedBox(height: 24),

        // Shared Intentions Section
        _SectionHeader(
          title: 'Shared Intentions',
          icon: LucideIcons.heart,
          actionLabel: 'See all',
          onAction: () {},
        ),
        const SizedBox(height: 12),

        ..._mockSharedIntentions.map((intention) => _SharedIntentionCard(
              intention: intention,
              isDark: isDark,
            )),

        const SizedBox(height: 24),

        // Prayer Groups Section
        _SectionHeader(
          title: 'Your Groups',
          icon: LucideIcons.users,
          actionLabel: 'Join more',
          onAction: () {},
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _mockPrayerGroups.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < _mockPrayerGroups.length - 1 ? 12 : 0,
                ),
                child: _PrayerGroupCard(
                  group: _mockPrayerGroups[index],
                  isDark: isDark,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }
}

/// Section header widget with optional action button.
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// Friend activity card widget.
class _FriendActivityCard extends StatelessWidget {
  final _FriendActivity activity;
  final bool isDark;

  const _FriendActivityCard({
    required this.activity,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: activity.avatarColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                activity.name[0],
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: activity.avatarColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    children: [
                      TextSpan(
                        text: activity.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${activity.action}'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            activity.icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

/// Shared intention card widget.
class _SharedIntentionCard extends StatelessWidget {
  final _SharedIntention intention;
  final bool isDark;

  const _SharedIntentionCard({
    required this.intention,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    intention.author[0],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  intention.author,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Text(
                intention.timeAgo,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            intention.content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _IntentionStat(
                icon: LucideIcons.heart,
                count: intention.prayerCount,
                label: 'praying',
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _IntentionStat(
                icon: LucideIcons.messageCircle,
                count: intention.commentCount,
                label: 'comments',
                isDark: isDark,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.handMetal, size: 16),
                label: const Text('Pray'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Intention stat widget.
class _IntentionStat extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final bool isDark;

  const _IntentionStat({
    required this.icon,
    required this.count,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

/// Prayer group card widget.
class _PrayerGroupCard extends StatelessWidget {
  final _PrayerGroup group;
  final bool isDark;

  const _PrayerGroupCard({
    required this.group,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            group.color,
            group.color.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            group.icon,
            color: Colors.white,
            size: 24,
          ),
          const Spacer(),
          Text(
            group.name,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${group.memberCount} members',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Mock Data Models
// ============================================================================

class _FriendActivity {
  final String name;
  final String action;
  final String timeAgo;
  final Color avatarColor;
  final IconData icon;

  const _FriendActivity({
    required this.name,
    required this.action,
    required this.timeAgo,
    required this.avatarColor,
    required this.icon,
  });
}

class _SharedIntention {
  final String author;
  final String content;
  final String timeAgo;
  final int prayerCount;
  final int commentCount;

  const _SharedIntention({
    required this.author,
    required this.content,
    required this.timeAgo,
    required this.prayerCount,
    required this.commentCount,
  });
}

class _PrayerGroup {
  final String name;
  final int memberCount;
  final Color color;
  final IconData icon;

  const _PrayerGroup({
    required this.name,
    required this.memberCount,
    required this.color,
    required this.icon,
  });
}

// Mock data
const _mockFriendActivities = [
  _FriendActivity(
    name: 'Sarah M.',
    action: 'completed a 7-day prayer streak',
    timeAgo: '2h ago',
    avatarColor: Color(0xFF30D158),
    icon: LucideIcons.flame,
  ),
  _FriendActivity(
    name: 'David K.',
    action: 'started praying for your intention',
    timeAgo: '4h ago',
    avatarColor: Color(0xFF5856D6),
    icon: LucideIcons.heart,
  ),
  _FriendActivity(
    name: 'Emma R.',
    action: 'shared a prayer request',
    timeAgo: '6h ago',
    avatarColor: Color(0xFFFF9500),
    icon: LucideIcons.share2,
  ),
];

const _mockSharedIntentions = [
  _SharedIntention(
    author: 'Michael T.',
    content: 'Please pray for my grandmother who is in the hospital. She has been fighting pneumonia for two weeks.',
    timeAgo: '1h ago',
    prayerCount: 24,
    commentCount: 5,
  ),
  _SharedIntention(
    author: 'Grace L.',
    content: 'Praying for wisdom as I start my new job next week. Would appreciate your prayers!',
    timeAgo: '3h ago',
    prayerCount: 18,
    commentCount: 3,
  ),
];

const _mockPrayerGroups = [
  _PrayerGroup(
    name: 'Morning Devotion',
    memberCount: 156,
    color: Color(0xFF673AB7),
    icon: LucideIcons.sunrise,
  ),
  _PrayerGroup(
    name: 'Youth Ministry',
    memberCount: 89,
    color: Color(0xFF30D158),
    icon: LucideIcons.users,
  ),
  _PrayerGroup(
    name: 'Healing Circle',
    memberCount: 234,
    color: Color(0xFFFF9500),
    icon: LucideIcons.heart,
  ),
];

// ============================================================================
// Original Today View Components (Preserved)
// ============================================================================

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
