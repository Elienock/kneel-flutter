import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import '../../domain/entities/prayer_group.dart';
import '../bloc/community_cubit.dart';
import '../bloc/community_state.dart';
import '../widgets/activity_feed_section.dart';
import '../widgets/shared_intentions_section.dart';
import '../widgets/my_groups_section.dart';
import 'friends_page.dart';
import 'discover_groups_page.dart';
import '../widgets/create_intention_sheet.dart';

/// Main Community page with tabbed sections.
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load data when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityCubit>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: false,
        actions: [
          // Friends button with badge for requests
          BlocBuilder<CommunityCubit, CommunityState>(
            builder: (context, state) {
              final requestCount = state.friendRequests.length;
              return Stack(
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
                  if (requestCount > 0)
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
                          '$requestCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(150),
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'Intentions'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: BlocBuilder<CommunityCubit, CommunityState>(
        builder: (context, state) {
          if (state.isLoading && state.activities.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Activity Feed Tab
              RefreshIndicator(
                onRefresh: () => context.read<CommunityCubit>().loadActivityFeed(),
                child: const ActivityFeedSection(),
              ),

              // Shared Intentions Tab
              RefreshIndicator(
                onRefresh: () => context.read<CommunityCubit>().loadIntentions(),
                child: const SharedIntentionsSection(),
              ),

              // My Groups Tab
              RefreshIndicator(
                onRefresh: () => context.read<CommunityCubit>().loadMyGroups(),
                child: const MyGroupsSection(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showCreateOptions(context);
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('Share'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    final cubit = context.read<CommunityCubit>();

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.heart, color: AppTheme.primaryColor),
                ),
                title: const Text('Share Prayer Request'),
                subtitle: const Text('Ask your community to pray with you'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  CreateIntentionSheet.show(context, cubit);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.users, color: AppTheme.secondaryColor),
                ),
                title: const Text('Create Prayer Group'),
                subtitle: const Text('Start a new prayer community'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showCreateGroupSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedPrivacy = 'public';
    String? selectedCategory;

    final categories = ['Family', 'Youth', 'Healing', 'Career', 'Marriage', 'Singles', 'Daily Prayer', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.users, color: AppTheme.secondaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Create Prayer Group',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'e.g., Morning Prayer Warriors',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What is this group about?',
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  Text('Privacy', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'public', label: Text('Public'), icon: Icon(LucideIcons.globe, size: 16)),
                      ButtonSegment(value: 'private', label: Text('Private'), icon: Icon(LucideIcons.lock, size: 16)),
                      ButtonSegment(value: 'invite', label: Text('Invite'), icon: Icon(LucideIcons.mail, size: 16)),
                    ],
                    selected: {selectedPrivacy},
                    onSelectionChanged: (value) {
                      setSheetState(() => selectedPrivacy = value.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  Text('Category (Optional)', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          setSheetState(() => selectedCategory = selected ? cat : null);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;

                        final privacy = switch (selectedPrivacy) {
                          'private' => GroupPrivacy.private,
                          'invite' => GroupPrivacy.inviteOnly,
                          _ => GroupPrivacy.public,
                        };

                        await context.read<CommunityCubit>().createGroup(
                          name: nameController.text.trim(),
                          description: descController.text.trim(),
                          privacy: privacy,
                          category: selectedCategory,
                        );

                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Create Group'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
