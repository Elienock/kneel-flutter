import 'friend.dart';
import 'shared_intention.dart';

/// Privacy level of a prayer group.
enum GroupPrivacy {
  public,    // Anyone can join
  private,   // Request to join required
  inviteOnly, // Must be invited
}

/// Role of a member in a group.
enum GroupRole {
  admin,
  moderator,
  member,
}

/// Member of a prayer group.
class GroupMember {
  final Friend friend;
  final GroupRole role;
  final DateTime joinedAt;

  const GroupMember({
    required this.friend,
    required this.role,
    required this.joinedAt,
  });
}

/// Represents a prayer group in the community.
class PrayerGroup {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final GroupPrivacy privacy;
  final int memberCount;
  final List<GroupMember> members;
  final List<SharedIntention> intentions;
  final DateTime createdAt;
  final bool isMember;      // Whether current user is a member
  final bool isAdmin;       // Whether current user is admin
  final bool hasPendingRequest; // Whether user has pending join request
  final String? category;   // e.g., "Healing", "Family", "Youth"

  const PrayerGroup({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.privacy = GroupPrivacy.public,
    this.memberCount = 0,
    this.members = const [],
    this.intentions = const [],
    required this.createdAt,
    this.isMember = false,
    this.isAdmin = false,
    this.hasPendingRequest = false,
    this.category,
  });

  PrayerGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    GroupPrivacy? privacy,
    int? memberCount,
    List<GroupMember>? members,
    List<SharedIntention>? intentions,
    DateTime? createdAt,
    bool? isMember,
    bool? isAdmin,
    bool? hasPendingRequest,
    String? category,
  }) {
    return PrayerGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      privacy: privacy ?? this.privacy,
      memberCount: memberCount ?? this.memberCount,
      members: members ?? this.members,
      intentions: intentions ?? this.intentions,
      createdAt: createdAt ?? this.createdAt,
      isMember: isMember ?? this.isMember,
      isAdmin: isAdmin ?? this.isAdmin,
      hasPendingRequest: hasPendingRequest ?? this.hasPendingRequest,
      category: category ?? this.category,
    );
  }
}
