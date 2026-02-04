import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import '../../domain/entities/prayer_group.dart';
import '../bloc/community_cubit.dart';
import '../bloc/community_state.dart';
import 'group_detail_page.dart';

/// Page for discovering and joining prayer groups.
class DiscoverGroupsPage extends StatefulWidget {
  const DiscoverGroupsPage({super.key});

  @override
  State<DiscoverGroupsPage> createState() => _DiscoverGroupsPageState();
}

class _DiscoverGroupsPageState extends State<DiscoverGroupsPage> {
  final _searchController = TextEditingController();
  String? _selectedCategory;

  final _categories = [
    'All',
    'Family',
    'Youth',
    'Healing',
    'Career',
    'Marriage',
    'Singles',
    'Daily Prayer',
  ];

  @override
  void initState() {
    super.initState();
    context.read<CommunityCubit>().loadDiscoverGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Groups'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(LucideIcons.search),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                context.read<CommunityCubit>().searchGroups(value);
              },
            ),
          ),

          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = (_selectedCategory == null && category == 'All') ||
                    _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected && category != 'All' ? category : null;
                      });
                      context.read<CommunityCubit>().loadDiscoverGroups(
                        category: _selectedCategory,
                      );
                    },
                    selectedColor: AppTheme.primaryColor.withAlpha(50),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Groups list
          Expanded(
            child: BlocBuilder<CommunityCubit, CommunityState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.discoverGroups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.searchX,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No groups found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.discoverGroups.length,
                  itemBuilder: (context, index) {
                    return _DiscoverGroupCard(group: state.discoverGroups[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverGroupCard extends StatelessWidget {
  final PrayerGroup group;

  const _DiscoverGroupCard({required this.group});

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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_categoryIcon, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.memberCount} members',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            _getPrivacyIcon(group.privacy),
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPrivacyLabel(group.privacy),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              group.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(200),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (group.category != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  group.category!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: group.hasPendingRequest
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Request Pending'),
                    )
                  : FilledButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.read<CommunityCubit>().joinGroup(group.id);

                        final message = group.privacy == GroupPrivacy.public
                            ? 'Joined ${group.name}!'
                            : 'Request sent to join ${group.name}';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: Text(
                        group.privacy == GroupPrivacy.public ? 'Join Group' : 'Request to Join',
                      ),
                    ),
            ),
          ],
        ),
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
