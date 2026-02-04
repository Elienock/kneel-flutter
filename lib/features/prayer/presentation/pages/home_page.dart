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
import 'package:quick_church/features/pulpit/presentation/bloc/pulpit_cubit.dart';
import 'package:quick_church/features/pulpit/presentation/pages/pulpit_groups_page.dart';
import 'package:quick_church/features/community/presentation/bloc/community_cubit.dart';
import 'package:quick_church/features/community/presentation/bloc/community_state.dart';
import 'package:quick_church/features/community/presentation/pages/friends_page.dart';
import 'package:quick_church/features/community/presentation/pages/discover_groups_page.dart';
import 'package:quick_church/features/community/presentation/pages/group_detail_page.dart';
import 'package:quick_church/features/community/presentation/widgets/create_intention_sheet.dart';
import 'package:quick_church/features/community/presentation/widgets/intention_detail_sheet.dart';
import 'package:quick_church/features/community/domain/entities/friend_activity.dart';
import 'package:quick_church/features/community/domain/entities/shared_intention.dart';
import 'package:quick_church/features/community/domain/entities/prayer_group.dart';

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

            // Pulpit Mode Card (for leaders)
            const _PulpitModeCard(),
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
/// Now uses CommunityCubit for real data.
class _CommunityView extends StatefulWidget {
  const _CommunityView();

  @override
  State<_CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<_CommunityView> {
  @override
  void initState() {
    super.initState();
    // Load community data when view is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityCubit>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CommunityCubit, CommunityState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<CommunityCubit>().loadAll(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header with Friends & Search buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Friends button with badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.users),
                        tooltip: 'Friends',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<CommunityCubit>(),
                                child: const FriendsPage(),
                              ),
                            ),
                          );
                        },
                      ),
                      if (state.friendRequests.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.urgentColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${state.friendRequests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.search),
                    tooltip: 'Discover Groups',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<CommunityCubit>(),
                            child: const DiscoverGroupsPage(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Friends Activity Header
              const _SectionHeader(
                title: 'Friend Activity',
                icon: LucideIcons.activity,
              ),
              const SizedBox(height: 12),

              // Activity Feed from Cubit
              if (state.activities.isEmpty)
                _EmptyStateCard(
                  icon: LucideIcons.activity,
                  message: 'No activity yet. Connect with friends!',
                  isDark: isDark,
                )
              else
                ...state.activities.take(4).map((activity) => _ActivityCard(
                      activity: activity,
                      isDark: isDark,
                    )),

              const SizedBox(height: 24),

              // Shared Intentions Section
              _SectionHeader(
                title: 'Shared Intentions',
                icon: LucideIcons.heart,
                actionLabel: 'Share',
                onAction: () {
                  CreateIntentionSheet.show(context, context.read<CommunityCubit>());
                },
              ),
              const SizedBox(height: 12),

              if (state.intentions.isEmpty)
                _EmptyStateCard(
                  icon: LucideIcons.heart,
                  message: 'No prayer requests yet. Be the first to share!',
                  isDark: isDark,
                )
              else
                ...state.intentions.take(3).map((intention) => _IntentionCard(
                      intention: intention,
                      isDark: isDark,
                    )),

              const SizedBox(height: 24),

              // Prayer Groups Section
              _SectionHeader(
                title: 'Your Groups',
                icon: LucideIcons.users,
                actionLabel: 'Discover',
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<CommunityCubit>(),
                        child: const DiscoverGroupsPage(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              if (state.myGroups.isEmpty)
                _EmptyStateCard(
                  icon: LucideIcons.users,
                  message: 'Join a prayer group to connect with others.',
                  isDark: isDark,
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.myGroups.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < state.myGroups.length - 1 ? 12 : 0,
                        ),
                        child: _GroupCard(
                          group: state.myGroups[index],
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }
}

/// Empty state card for community sections.
class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;

  const _EmptyStateCard({
    required this.icon,
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withAlpha(50),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Activity card using real FriendActivity data.
class _ActivityCard extends StatelessWidget {
  final FriendActivity activity;
  final bool isDark;

  const _ActivityCard({
    required this.activity,
    required this.isDark,
  });

  (IconData, Color) _getActivityIcon() {
    switch (activity.type) {
      case ActivityType.startedPraying:
        return (LucideIcons.heart, AppTheme.primaryColor);
      case ActivityType.sharedIntention:
        return (LucideIcons.messageCircle, AppTheme.secondaryColor);
      case ActivityType.joinedGroup:
        return (LucideIcons.users, AppTheme.mediumColor);
      case ActivityType.answeredPrayer:
        return (LucideIcons.sparkles, AppTheme.answeredColor);
      case ActivityType.prayerStreak:
        return (LucideIcons.flame, AppTheme.goldenPromise);
      case ActivityType.newFriend:
        return (LucideIcons.userPlus, AppTheme.primaryColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getActivityIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 51 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    activity.friend.initials,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, size: 10, color: Colors.white),
                ),
              ),
            ],
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
                        text: activity.friend.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${activity.description}'),
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
        ],
      ),
    );
  }
}

/// Intention card using real SharedIntention data.
class _IntentionCard extends StatelessWidget {
  final SharedIntention intention;
  final bool isDark;

  const _IntentionCard({
    required this.intention,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = intention.status == IntentionStatus.answered;

    return GestureDetector(
      onTap: () => IntentionDetailSheet.show(context, intention),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAnswered
                ? AppTheme.answeredColor.withAlpha(100)
                : AppTheme.primaryColor.withAlpha(51),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 51 : 13),
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
                    color: AppTheme.primaryColor.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      intention.author.initials,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    intention.author.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (isAnswered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.answeredColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.answeredColor),
                        const SizedBox(width: 4),
                        Text(
                          'Answered',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.answeredColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  intention.hasPrayed ? LucideIcons.heartHandshake : LucideIcons.heart,
                  size: 14,
                  color: intention.hasPrayed ? AppTheme.primaryColor : (isDark ? Colors.white38 : Colors.black38),
                ),
                const SizedBox(width: 4),
                Text(
                  '${intention.prayerCount} praying',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: intention.hasPrayed ? AppTheme.primaryColor : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.messageCircle,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 4),
                Text(
                  '${intention.commentCount}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const Spacer(),
                if (!intention.hasPrayed && !isAnswered)
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.read<CommunityCubit>().prayForIntention(intention.id);
                    },
                    icon: const Icon(LucideIcons.heart, size: 14),
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
      ),
    );
  }
}

/// Group card using real PrayerGroup data.
class _GroupCard extends StatelessWidget {
  final PrayerGroup group;
  final bool isDark;

  const _GroupCard({
    required this.group,
    required this.isDark,
  });

  Color get _categoryColor {
    switch (group.category?.toLowerCase()) {
      case 'family':
        return const Color(0xFF673AB7);
      case 'youth':
        return const Color(0xFF30D158);
      case 'healing':
        return const Color(0xFFFF9500);
      case 'career':
        return const Color(0xFF007AFF);
      case 'marriage':
        return const Color(0xFFFF2D55);
      case 'daily prayer':
        return const Color(0xFF5856D6);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData get _categoryIcon {
    switch (group.category?.toLowerCase()) {
      case 'family':
        return LucideIcons.home;
      case 'youth':
        return LucideIcons.sparkles;
      case 'healing':
        return LucideIcons.heartHandshake;
      case 'career':
        return LucideIcons.briefcase;
      case 'marriage':
        return LucideIcons.heart;
      case 'daily prayer':
        return LucideIcons.sunrise;
      default:
        return LucideIcons.users;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<CommunityCubit>(),
              child: GroupDetailPage(group: group),
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _categoryColor,
              _categoryColor.withAlpha(179),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _categoryIcon,
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
      ),
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

/// Pulpit Mode card - quick access to lead group prayer sessions.
class _PulpitModeCard extends StatelessWidget {
  const _PulpitModeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => BlocProvider.value(
              value: context.read<PulpitCubit>(),
              child: const PulpitGroupsPage(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withAlpha(isDark ? 40 : 30),
              AppTheme.secondaryColor.withAlpha(isDark ? 30 : 20),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: AppTheme.primaryColor.withAlpha(50),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.mic2,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pulpit Mode',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lead group prayer sessions',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
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
