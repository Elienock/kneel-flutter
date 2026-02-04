import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/prayer_group.dart';
import '../../domain/entities/shared_intention.dart';
import '../bloc/community_cubit.dart';
import '../widgets/intention_detail_sheet.dart';

/// Page showing details of a prayer group.
class GroupDetailPage extends StatefulWidget {
  final PrayerGroup group;

  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData get _categoryIcon {
    switch (widget.group.category?.toLowerCase()) {
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
      case 'singles':
        return LucideIcons.user;
      case 'daily prayer':
        return LucideIcons.sunrise;
      default:
        return LucideIcons.users;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with group header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor.withAlpha(200),
                      AppTheme.primaryColor.withAlpha(100),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_categoryIcon, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.group.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.users, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.group.memberCount} members',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(width: 12),
                          Icon(_getPrivacyIcon(widget.group.privacy), size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            _getPrivacyLabel(widget.group.privacy),
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (widget.group.isMember)
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical),
                  onSelected: (value) {
                    if (value == 'leave') {
                      _showLeaveConfirmation(context);
                    } else if (value == 'settings') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Group settings coming soon!')),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    if (widget.group.isAdmin)
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(LucideIcons.settings, size: 18),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(LucideIcons.logOut, size: 18, color: AppTheme.urgentColor),
                          SizedBox(width: 8),
                          Text('Leave Group', style: TextStyle(color: AppTheme.urgentColor)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Description
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.group.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(200),
                      height: 1.5,
                    ),
                  ),
                  if (widget.group.category != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.group.category!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Join button for non-members
          if (!widget.group.isMember)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: widget.group.hasPendingRequest
                    ? OutlinedButton(
                        onPressed: null,
                        child: const Text('Request Pending'),
                      )
                    : FilledButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.read<CommunityCubit>().joinGroup(widget.group.id);
                          Navigator.pop(context);

                          final message = widget.group.privacy == GroupPrivacy.public
                              ? 'Joined ${widget.group.name}!'
                              : 'Request sent to join ${widget.group.name}';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                        child: Text(
                          widget.group.privacy == GroupPrivacy.public ? 'Join Group' : 'Request to Join',
                        ),
                      ),
              ),
            ),

          // Tab bar for members
          if (widget.group.isMember) ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryColor,
                  labelColor: theme.colorScheme.onSurface,
                  unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(150),
                  tabs: const [
                    Tab(text: 'Prayers'),
                    Tab(text: 'Members'),
                    Tab(text: 'Activity'),
                  ],
                ),
                isDark ? const Color(0xFF1C1C1E) : Colors.white,
              ),
            ),

            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPrayersTab(context),
                  _buildMembersTab(context),
                  _buildActivityTab(context),
                ],
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: widget.group.isMember
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group prayer request coming soon!')),
                );
              },
              icon: const Icon(LucideIcons.plus),
              label: const Text('Request Prayer'),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
    );
  }

  Widget _buildPrayersTab(BuildContext context) {
    final theme = Theme.of(context);

    // Mock intentions for the group
    final mockIntentions = [
      SharedIntention(
        id: 'gi1',
        author: widget.group.members.isNotEmpty
            ? widget.group.members[0].friend
            : const Friend(id: 'mock', name: 'Group Member'),
        content: 'Please pray for our group\'s upcoming prayer retreat next month.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        prayerCount: 12,
        commentCount: 5,
      ),
      SharedIntention(
        id: 'gi2',
        author: const Friend(id: 'mock2', name: 'Prayer Leader'),
        content: 'Lifting up all members going through difficult seasons.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        prayerCount: 28,
        commentCount: 8,
        hasPrayed: true,
      ),
    ];

    if (mockIntentions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.heart, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No prayer requests yet',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share a prayer request',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockIntentions.length,
      itemBuilder: (context, index) {
        final intention = mockIntentions[index];
        return _GroupIntentionCard(intention: intention);
      },
    );
  }

  Widget _buildMembersTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mock members
    final mockMembers = [
      GroupMember(
        friend: const Friend(id: 'm1', name: 'You', bio: 'Group Admin'),
        role: GroupRole.admin,
        joinedAt: DateTime(2024, 1, 1),
      ),
      ...widget.group.members,
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockMembers.length,
      itemBuilder: (context, index) {
        final member = mockMembers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withAlpha(25),
                child: Text(
                  member.friend.initials,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.friend.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (member.friend.bio != null)
                      Text(
                        member.friend.bio!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                  ],
                ),
              ),
              if (member.role == GroupRole.admin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Admin',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                )
              else if (member.role == GroupRole.moderator)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.mediumColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Mod',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mediumColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityTab(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.activity, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Group activity coming soon',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group?'),
        content: Text('Are you sure you want to leave "${widget.group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CommunityCubit>().leaveGroup(widget.group.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.urgentColor),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  IconData _getPrivacyIcon(GroupPrivacy privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return LucideIcons.globe;
      case GroupPrivacy.private:
        return LucideIcons.lock;
      case GroupPrivacy.inviteOnly:
        return LucideIcons.mail;
    }
  }

  String _getPrivacyLabel(GroupPrivacy privacy) {
    switch (privacy) {
      case GroupPrivacy.public:
        return 'Public';
      case GroupPrivacy.private:
        return 'Private';
      case GroupPrivacy.inviteOnly:
        return 'Invite Only';
    }
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _GroupIntentionCard extends StatelessWidget {
  final SharedIntention intention;

  const _GroupIntentionCard({required this.intention});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => IntentionDetailSheet.show(context, intention),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor.withAlpha(25),
                  child: Text(
                    intention.author.initials,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  intention.author.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  intention.timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              intention.content,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  intention.hasPrayed ? LucideIcons.heartHandshake : LucideIcons.heart,
                  size: 16,
                  color: intention.hasPrayed ? AppTheme.primaryColor : theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  '${intention.prayerCount} praying',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: intention.hasPrayed ? AppTheme.primaryColor : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(LucideIcons.messageCircle, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${intention.commentCount}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

