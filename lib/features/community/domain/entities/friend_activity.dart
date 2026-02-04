import 'friend.dart';

/// Types of activities in the friend activity feed.
enum ActivityType {
  startedPraying,    // Friend started praying for your intention
  sharedIntention,   // Friend shared a new prayer request
  joinedGroup,       // Friend joined a prayer group
  answeredPrayer,    // Friend's prayer was answered
  prayerStreak,      // Friend achieved a prayer streak
  newFriend,         // You have a new friend connection
}

/// Represents an activity item in the friend activity feed.
class FriendActivity {
  final String id;
  final Friend friend;
  final ActivityType type;
  final DateTime timestamp;
  final String? targetTitle;      // e.g., prayer title, group name
  final String? targetId;         // ID of the related entity
  final int? streakCount;         // For streak activities

  const FriendActivity({
    required this.id,
    required this.friend,
    required this.type,
    required this.timestamp,
    this.targetTitle,
    this.targetId,
    this.streakCount,
  });

  String get description {
    switch (type) {
      case ActivityType.startedPraying:
        return 'started praying for your intention';
      case ActivityType.sharedIntention:
        return 'shared a prayer request';
      case ActivityType.joinedGroup:
        return 'joined $targetTitle';
      case ActivityType.answeredPrayer:
        return 'prayer was answered!';
      case ActivityType.prayerStreak:
        return 'achieved a $streakCount-day prayer streak!';
      case ActivityType.newFriend:
        return 'connected with you';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
