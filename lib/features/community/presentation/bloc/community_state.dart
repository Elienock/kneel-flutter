import '../../domain/entities/friend.dart';
import '../../domain/entities/friend_activity.dart';
import '../../domain/entities/shared_intention.dart';
import '../../domain/entities/prayer_group.dart';

/// State for the Community feature.
class CommunityState {
  final bool isLoading;
  final String? error;

  // Friends
  final List<Friend> friends;
  final List<Friend> suggestedFriends;
  final List<FriendRequest> friendRequests;

  // Activity Feed
  final List<FriendActivity> activities;

  // Shared Intentions
  final List<SharedIntention> intentions;

  // Groups
  final List<PrayerGroup> myGroups;
  final List<PrayerGroup> discoverGroups;
  final PrayerGroup? selectedGroup;

  const CommunityState({
    this.isLoading = false,
    this.error,
    this.friends = const [],
    this.suggestedFriends = const [],
    this.friendRequests = const [],
    this.activities = const [],
    this.intentions = const [],
    this.myGroups = const [],
    this.discoverGroups = const [],
    this.selectedGroup,
  });

  CommunityState copyWith({
    bool? isLoading,
    String? error,
    List<Friend>? friends,
    List<Friend>? suggestedFriends,
    List<FriendRequest>? friendRequests,
    List<FriendActivity>? activities,
    List<SharedIntention>? intentions,
    List<PrayerGroup>? myGroups,
    List<PrayerGroup>? discoverGroups,
    PrayerGroup? selectedGroup,
    bool clearError = false,
    bool clearSelectedGroup = false,
  }) {
    return CommunityState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      friends: friends ?? this.friends,
      suggestedFriends: suggestedFriends ?? this.suggestedFriends,
      friendRequests: friendRequests ?? this.friendRequests,
      activities: activities ?? this.activities,
      intentions: intentions ?? this.intentions,
      myGroups: myGroups ?? this.myGroups,
      discoverGroups: discoverGroups ?? this.discoverGroups,
      selectedGroup: clearSelectedGroup ? null : (selectedGroup ?? this.selectedGroup),
    );
  }
}
