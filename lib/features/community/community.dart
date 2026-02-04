/// Community Feature
///
/// Social prayer community features including friends, groups,
/// shared intentions, and activity feeds.
///
/// Features:
/// - Friend connections and discovery
/// - Prayer groups with shared intentions
/// - Activity feed showing friend prayer activity
/// - Shared prayer requests with pray/comment support
///
/// Usage:
/// ```dart
/// // Add CommunityCubit to your providers
/// BlocProvider(
///   create: (_) => CommunityCubit()..loadAll(),
/// ),
///
/// // Use CommunityPage in your navigation
/// const CommunityPage()
/// ```
library community;

export 'domain/entities/friend.dart';
export 'domain/entities/friend_activity.dart';
export 'domain/entities/shared_intention.dart';
export 'domain/entities/prayer_group.dart';
export 'domain/entities/testimony.dart';
export 'data/repositories/community_repository.dart';
export 'presentation/bloc/community_cubit.dart';
export 'presentation/bloc/community_state.dart';
export 'presentation/pages/community_page.dart';
export 'presentation/pages/friends_page.dart';
export 'presentation/pages/discover_groups_page.dart';
export 'presentation/pages/group_detail_page.dart';
export 'presentation/pages/friend_profile_page.dart';
export 'presentation/pages/all_activities_page.dart';
export 'presentation/pages/all_intentions_page.dart';
export 'presentation/pages/all_testimonies_page.dart';
export 'presentation/widgets/testimony_detail_sheet.dart';
