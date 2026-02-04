import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/friend_activity.dart';
import '../../domain/entities/testimony.dart';
import '../../domain/entities/prayer_group.dart';
import '../bloc/community_cubit.dart';
import 'group_detail_page.dart';

/// Friend profile page showing their activity, testimonies, and groups.
class FriendProfilePage extends StatelessWidget {
  final Friend friend;

  const FriendProfilePage({super.key, required this.friend});

  static void show(BuildContext context, Friend friend) {
    final cubit = context.read<CommunityCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: FriendProfilePage(friend: friend),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mock data for this friend's profile
    final mockActivities = [
      FriendActivity(
        id: 'fa1',
        friend: friend,
        type: ActivityType.startedPraying,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        targetTitle: 'your prayer for healing',
      ),
      FriendActivity(
        id: 'fa2',
        friend: friend,
        type: ActivityType.sharedIntention,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      FriendActivity(
        id: 'fa3',
        friend: friend,
        type: ActivityType.joinedGroup,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        targetTitle: 'Morning Prayer Warriors',
      ),
      FriendActivity(
        id: 'fa4',
        friend: friend,
        type: ActivityType.answeredPrayer,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        targetTitle: 'job interview',
      ),
      FriendActivity(
        id: 'fa5',
        friend: friend,
        type: ActivityType.prayerStreak,
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        streakCount: 30,
      ),
    ];

    final mockTestimonies = [
      SharedTestimony(
        id: 't1',
        author: friend,
        title: 'God answered my prayer!',
        story: 'After months of praying, I finally got the job I was hoping for. God is so faithful!',
        answeredAt: DateTime.now().subtract(const Duration(days: 7)),
        sharedAt: DateTime.now().subtract(const Duration(days: 5)),
        celebrationCount: 24,
        commentCount: 8,
      ),
    ];

    final mockGroups = [
      PrayerGroup(
        id: 'g1',
        name: 'Morning Prayer Warriors',
        description: 'Daily morning prayer group',
        memberCount: 156,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        isMember: true,
        category: 'Daily Prayer',
      ),
      PrayerGroup(
        id: 'g2',
        name: 'Family Prayer Circle',
        description: 'Praying for our families',
        memberCount: 23,
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
        isMember: true,
        category: 'Family',
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withAlpha(200),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            friend.initials,
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        friend.name,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (friend.bio != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          friend.bio!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Online status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: friend.isOnline ? AppTheme.answeredColor : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            friend.isOnline ? 'Online now' : 'Last seen recently',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
                onSelected: (value) {
                  if (value == 'remove') {
                    _showRemoveFriendDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(LucideIcons.userMinus, size: 18, color: AppTheme.urgentColor),
                        SizedBox(width: 8),
                        Text('Remove Friend', style: TextStyle(color: AppTheme.urgentColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Stats Row
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.flame,
                      value: '45',
                      label: 'Day Streak',
                      color: AppTheme.goldenPromise,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.heart,
                      value: '234',
                      label: 'Prayers',
                      color: AppTheme.primaryColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.sparkles,
                      value: '12',
                      label: 'Answered',
                      color: AppTheme.answeredColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent Activity Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.activity, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final activity = mockActivities[index];
                return _ActivityItem(activity: activity, isDark: isDark);
              },
              childCount: mockActivities.length,
            ),
          ),

          // Testimonies Section
          if (mockTestimonies.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    const Icon(LucideIcons.trophy, size: 20, color: AppTheme.answeredColor),
                    const SizedBox(width: 8),
                    Text(
                      'Testimonies',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final testimony = mockTestimonies[index];
                  return _TestimonyCard(testimony: testimony, isDark: isDark);
                },
                childCount: mockTestimonies.length,
              ),
            ),
          ],

          // Groups in Common Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.users, size: 20, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Groups in Common',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: mockGroups.length,
                itemBuilder: (context, index) {
                  final group = mockGroups[index];
                  return Padding(
                    padding: EdgeInsets.only(right: index < mockGroups.length - 1 ? 12 : 0),
                    child: _GroupChip(
                      group: group,
                      isDark: isDark,
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
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  void _showRemoveFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Friend?'),
        content: Text('Are you sure you want to remove ${friend.name} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${friend.name} removed from friends')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.urgentColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final FriendActivity activity;
  final bool isDark;

  const _ActivityItem({required this.activity, required this.isDark});

  IconData get _icon {
    switch (activity.type) {
      case ActivityType.startedPraying:
        return LucideIcons.heart;
      case ActivityType.sharedIntention:
        return LucideIcons.messageCircle;
      case ActivityType.joinedGroup:
        return LucideIcons.users;
      case ActivityType.answeredPrayer:
        return LucideIcons.sparkles;
      case ActivityType.prayerStreak:
        return LucideIcons.flame;
      case ActivityType.newFriend:
        return LucideIcons.userPlus;
    }
  }

  Color get _color {
    switch (activity.type) {
      case ActivityType.startedPraying:
        return AppTheme.primaryColor;
      case ActivityType.sharedIntention:
        return AppTheme.secondaryColor;
      case ActivityType.joinedGroup:
        return AppTheme.mediumColor;
      case ActivityType.answeredPrayer:
        return AppTheme.answeredColor;
      case ActivityType.prayerStreak:
        return AppTheme.goldenPromise;
      case ActivityType.newFriend:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withAlpha(13),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
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

class _TestimonyCard extends StatelessWidget {
  final SharedTestimony testimony;
  final bool isDark;

  const _TestimonyCard({required this.testimony, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.answeredColor.withAlpha(100),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.answeredColor.withAlpha(25),
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
              const Icon(LucideIcons.trophy, size: 18, color: AppTheme.answeredColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  testimony.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.answeredColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            testimony.story,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.partyPopper, size: 14, color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 4),
              Text(
                '${testimony.celebrationCount} celebrating',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const Spacer(),
              Text(
                testimony.timeAgo,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final PrayerGroup group;
  final bool isDark;
  final VoidCallback onTap;

  const _GroupChip({
    required this.group,
    required this.isDark,
    required this.onTap,
  });

  Color get _color {
    switch (group.category?.toLowerCase()) {
      case 'family':
        return const Color(0xFF673AB7);
      case 'daily prayer':
        return const Color(0xFF5856D6);
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_color, _color.withAlpha(200)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              group.name,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${group.memberCount} members',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
