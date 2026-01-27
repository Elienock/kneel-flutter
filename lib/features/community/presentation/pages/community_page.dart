import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Community page showing prayer groups and shared intentions.
/// This is a UI shell - full functionality coming in future release.
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Coming Soon Banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha:0.1),
                    theme.colorScheme.secondary.withValues(alpha:0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha:0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.users,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community Features Coming Soon',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join prayer groups and share intentions with your community.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Header: My Groups
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Groups',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Create'),
                  ),
                ],
              ),
            ),
          ),

          // Mock Groups List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _MockGroupCard(
                group: _mockGroups[index],
              ),
              childCount: _mockGroups.length,
            ),
          ),

          // Section Header: Shared Intentions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'Shared Intentions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Mock Intentions List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _MockIntentionCard(
                intention: _mockIntentions[index],
              ),
              childCount: _mockIntentions.length,
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _MockGroup {
  final String name;
  final String description;
  final int memberCount;
  final IconData icon;

  const _MockGroup({
    required this.name,
    required this.description,
    required this.memberCount,
    required this.icon,
  });
}

const _mockGroups = [
  _MockGroup(
    name: 'Family Prayer Circle',
    description: 'Daily prayers for our family',
    memberCount: 8,
    icon: LucideIcons.home,
  ),
  _MockGroup(
    name: 'Church Youth Group',
    description: 'Young adults prayer community',
    memberCount: 24,
    icon: LucideIcons.church,
  ),
  _MockGroup(
    name: 'Morning Prayer Warriors',
    description: 'Start each day with prayer',
    memberCount: 156,
    icon: LucideIcons.sunrise,
  ),
  _MockGroup(
    name: 'Healing & Comfort',
    description: 'Prayers for those in need',
    memberCount: 89,
    icon: LucideIcons.heartHandshake,
  ),
];

class _MockGroupCard extends StatelessWidget {
  final _MockGroup group;

  const _MockGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha:0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            group.icon,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          group.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${group.memberCount} members',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha:0.6),
          ),
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          color: theme.colorScheme.onSurface.withValues(alpha:0.4),
        ),
      ),
    );
  }
}

class _MockIntention {
  final String author;
  final String content;
  final int prayerCount;
  final String timeAgo;

  const _MockIntention({
    required this.author,
    required this.content,
    required this.prayerCount,
    required this.timeAgo,
  });
}

const _mockIntentions = [
  _MockIntention(
    author: 'Sarah M.',
    content: 'Please pray for my grandmother\'s recovery from surgery.',
    prayerCount: 45,
    timeAgo: '2h ago',
  ),
  _MockIntention(
    author: 'John D.',
    content: 'Seeking guidance for an important career decision.',
    prayerCount: 32,
    timeAgo: '4h ago',
  ),
  _MockIntention(
    author: 'Grace L.',
    content: 'Prayers for peace and strength during difficult times.',
    prayerCount: 78,
    timeAgo: '6h ago',
  ),
  _MockIntention(
    author: 'Michael R.',
    content: 'Thanksgiving for answered prayers - my son got the job!',
    prayerCount: 124,
    timeAgo: '1d ago',
  ),
];

class _MockIntentionCard extends StatelessWidget {
  final _MockIntention intention;

  const _MockIntentionCard({required this.intention});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha:0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary.withValues(alpha:0.2),
                child: Text(
                  intention.author[0],
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                intention.author,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                intention.timeAgo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            intention.content,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.heart,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${intention.prayerCount} praying',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('Pray'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
