import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import '../../domain/entities/friend_activity.dart';
import '../bloc/community_cubit.dart';
import '../bloc/community_state.dart';
import 'friend_profile_page.dart';

/// Full list page for all friend activities.
class AllActivitiesPage extends StatelessWidget {
  const AllActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Activity'),
      ),
      body: BlocBuilder<CommunityCubit, CommunityState>(
        builder: (context, state) {
          if (state.activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.activity, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with friends to see their activity',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<CommunityCubit>().loadActivityFeed(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.activities.length,
              itemBuilder: (context, index) {
                return _ActivityCard(
                  activity: state.activities[index],
                  isDark: isDark,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Activity card with context navigation.
/// - Tap avatar → Friend profile
/// - Tap card → Navigate to activity context (intention, group, testimony, etc.)
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

  /// Navigate to the context of the activity.
  void _navigateToContext(BuildContext context) {
    HapticFeedback.selectionClick();

    switch (activity.type) {
      case ActivityType.startedPraying:
      case ActivityType.sharedIntention:
        // TODO: Fetch intention by activity.targetId from backend
        _showContextMessage(context, 'Opening prayer request...');
        break;

      case ActivityType.joinedGroup:
        // TODO: Fetch group by activity.targetId from backend
        _showContextMessage(context, 'Opening ${activity.targetTitle ?? "group"}...');
        break;

      case ActivityType.answeredPrayer:
        // TODO: Fetch testimony by activity.targetId from backend
        _showContextMessage(context, 'Opening testimony...');
        break;

      case ActivityType.prayerStreak:
      case ActivityType.newFriend:
        FriendProfilePage.show(context, activity.friend);
        break;
    }
  }

  void _showContextMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    FriendProfilePage.show(context, activity.friend);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getActivityIcon();

    return GestureDetector(
      onTap: () => _navigateToContext(context),
      child: Container(
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
            // Tappable Avatar (stops propagation to go to profile)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                FriendProfilePage.show(context, activity.friend);
              },
              child: Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        activity.friend.initials,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
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
                  if (activity.targetTitle != null && activity.type != ActivityType.joinedGroup) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"${activity.targetTitle}"',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        activity.timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
