/// Represents a friend/connection in the community.
class Friend {
  final String id;
  final String name;
  final String? photoUrl;
  final String? bio;
  final DateTime? lastActive;
  final int mutualFriends;
  final bool isOnline;

  const Friend({
    required this.id,
    required this.name,
    this.photoUrl,
    this.bio,
    this.lastActive,
    this.mutualFriends = 0,
    this.isOnline = false,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// Friend request status.
enum FriendRequestStatus {
  pending,
  accepted,
  declined,
}

/// Represents a friend request.
class FriendRequest {
  final String id;
  final Friend from;
  final DateTime sentAt;
  final FriendRequestStatus status;
  final bool isIncoming;

  const FriendRequest({
    required this.id,
    required this.from,
    required this.sentAt,
    this.status = FriendRequestStatus.pending,
    this.isIncoming = true,
  });
}
