import '../../domain/entities/friend.dart';
import '../../domain/entities/friend_activity.dart';
import '../../domain/entities/shared_intention.dart';
import '../../domain/entities/prayer_group.dart';

/// Repository for community data.
/// Currently uses mock data - ready for Supabase integration.
class CommunityRepository {
  // Mock data for simulation
  static final List<Friend> _mockFriends = [
    Friend(
      id: 'f1',
      name: 'David Miller',
      bio: 'Walking by faith, not by sight.',
      lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
      mutualFriends: 12,
      isOnline: true,
    ),
    Friend(
      id: 'f2',
      name: 'Emma Thompson',
      bio: 'Prayer warrior | Mom of 3',
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      mutualFriends: 8,
      isOnline: true,
    ),
    Friend(
      id: 'f3',
      name: 'Sarah Johnson',
      bio: 'Grateful for God\'s grace every day',
      lastActive: DateTime.now().subtract(const Duration(hours: 6)),
      mutualFriends: 5,
      isOnline: false,
    ),
    Friend(
      id: 'f4',
      name: 'Michael Chen',
      bio: 'Youth pastor | Coffee enthusiast',
      lastActive: DateTime.now().subtract(const Duration(days: 1)),
      mutualFriends: 15,
      isOnline: false,
    ),
    Friend(
      id: 'f5',
      name: 'Grace Williams',
      bio: 'Serving God through music ministry',
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
      mutualFriends: 7,
      isOnline: true,
    ),
    Friend(
      id: 'f6',
      name: 'John Peterson',
      bio: 'Bible study leader | Retired teacher',
      lastActive: DateTime.now().subtract(const Duration(days: 2)),
      mutualFriends: 3,
      isOnline: false,
    ),
  ];

  static final List<Friend> _suggestedFriends = [
    Friend(
      id: 's1',
      name: 'Rachel Adams',
      bio: 'New to the church family!',
      mutualFriends: 4,
    ),
    Friend(
      id: 's2',
      name: 'James Wilson',
      bio: 'Small group leader',
      mutualFriends: 6,
    ),
    Friend(
      id: 's3',
      name: 'Lisa Martinez',
      bio: 'Children\'s ministry volunteer',
      mutualFriends: 2,
    ),
  ];

  static List<FriendRequest> _pendingRequests = [
    FriendRequest(
      id: 'r1',
      from: const Friend(
        id: 'req1',
        name: 'Hannah Brown',
        bio: 'College student | Worship team',
        mutualFriends: 3,
      ),
      sentAt: DateTime.now().subtract(const Duration(hours: 4)),
      isIncoming: true,
    ),
    FriendRequest(
      id: 'r2',
      from: const Friend(
        id: 'req2',
        name: 'Daniel Kim',
        bio: 'New believer seeking community',
        mutualFriends: 1,
      ),
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
      isIncoming: true,
    ),
  ];

  static List<FriendActivity> _mockActivities = [];
  static List<SharedIntention> _mockIntentions = [];
  static List<PrayerGroup> _mockGroups = [];
  static List<PrayerGroup> _discoverGroups = [];

  static bool _initialized = false;

  static void _initMockData() {
    if (_initialized) return;
    _initialized = true;

    // Initialize activities
    _mockActivities = [
      FriendActivity(
        id: 'a1',
        friend: _mockFriends[0],
        type: ActivityType.startedPraying,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        targetTitle: 'your intention about family healing',
      ),
      FriendActivity(
        id: 'a2',
        friend: _mockFriends[1],
        type: ActivityType.sharedIntention,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      FriendActivity(
        id: 'a3',
        friend: _mockFriends[2],
        type: ActivityType.joinedGroup,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        targetTitle: 'Morning Prayer Warriors',
      ),
      FriendActivity(
        id: 'a4',
        friend: _mockFriends[4],
        type: ActivityType.answeredPrayer,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        targetTitle: 'Job interview prayer',
      ),
      FriendActivity(
        id: 'a5',
        friend: _mockFriends[3],
        type: ActivityType.prayerStreak,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        streakCount: 30,
      ),
      FriendActivity(
        id: 'a6',
        friend: _mockFriends[5],
        type: ActivityType.newFriend,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    // Initialize shared intentions
    _mockIntentions = [
      SharedIntention(
        id: 'i1',
        author: _mockFriends[1],
        content: 'Please pray for my mom\'s surgery tomorrow morning. She\'s nervous but trusting in God.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        prayerCount: 47,
        commentCount: 12,
        comments: [
          IntentionComment(
            id: 'c1',
            author: _mockFriends[0],
            content: 'Praying for peace and successful surgery! God is with her.',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          IntentionComment(
            id: 'c2',
            author: _mockFriends[4],
            content: 'Lifting her up in prayer right now. Trust in the Lord!',
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
      ),
      SharedIntention(
        id: 'i2',
        author: _mockFriends[3],
        content: 'Seeking guidance for an important career decision. Should I take the new position or stay?',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        prayerCount: 32,
        commentCount: 8,
        hasPrayed: true,
      ),
      SharedIntention(
        id: 'i3',
        author: _mockFriends[4],
        content: 'Prayers for peace and strength during these difficult times. Going through a season of trials.',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        prayerCount: 78,
        commentCount: 15,
      ),
      SharedIntention(
        id: 'i4',
        author: _mockFriends[2],
        content: 'Thanksgiving! My son got the job he was praying for! God is so faithful!',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: IntentionStatus.answered,
        prayerCount: 124,
        commentCount: 23,
        hasPrayed: true,
      ),
      SharedIntention(
        id: 'i5',
        author: _mockFriends[5],
        content: 'Please pray for our marriage. We\'re going through a challenging season but believing for restoration.',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        prayerCount: 89,
        commentCount: 19,
      ),
    ];

    // Initialize my groups
    _mockGroups = [
      PrayerGroup(
        id: 'g1',
        name: 'Family Prayer Circle',
        description: 'Daily prayers for our extended family. Supporting each other through life\'s journey.',
        privacy: GroupPrivacy.private,
        memberCount: 8,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        isMember: true,
        isAdmin: true,
        category: 'Family',
        members: [
          GroupMember(friend: _mockFriends[0], role: GroupRole.member, joinedAt: DateTime.now().subtract(const Duration(days: 60))),
          GroupMember(friend: _mockFriends[1], role: GroupRole.member, joinedAt: DateTime.now().subtract(const Duration(days: 45))),
        ],
      ),
      PrayerGroup(
        id: 'g2',
        name: 'Church Youth Group',
        description: 'Young adults prayer community. Growing together in faith and fellowship.',
        privacy: GroupPrivacy.public,
        memberCount: 24,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        isMember: true,
        category: 'Youth',
      ),
      PrayerGroup(
        id: 'g3',
        name: 'Morning Prayer Warriors',
        description: 'Start each day with prayer. We meet virtually at 6 AM daily.',
        privacy: GroupPrivacy.public,
        memberCount: 156,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        isMember: true,
        category: 'Daily Prayer',
      ),
    ];

    // Initialize discover groups
    _discoverGroups = [
      PrayerGroup(
        id: 'd1',
        name: 'Healing & Comfort',
        description: 'A supportive community for those going through health challenges. We believe in the power of prayer.',
        privacy: GroupPrivacy.public,
        memberCount: 234,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        category: 'Healing',
      ),
      PrayerGroup(
        id: 'd2',
        name: 'New Parents Prayer Support',
        description: 'Praying for new and expecting parents. Sharing joys and challenges of parenthood.',
        privacy: GroupPrivacy.public,
        memberCount: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        category: 'Family',
      ),
      PrayerGroup(
        id: 'd3',
        name: 'Career & Business',
        description: 'Praying for God\'s guidance in our professional lives. Kingdom-minded entrepreneurs.',
        privacy: GroupPrivacy.private,
        memberCount: 67,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        category: 'Career',
      ),
      PrayerGroup(
        id: 'd4',
        name: 'Singles Ministry',
        description: 'Supporting single Christians in their faith journey. You\'re not alone!',
        privacy: GroupPrivacy.public,
        memberCount: 145,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        category: 'Singles',
      ),
      PrayerGroup(
        id: 'd5',
        name: 'Marriage Enrichment',
        description: 'Praying for strong, God-centered marriages. Weekly prayer focus topics.',
        privacy: GroupPrivacy.inviteOnly,
        memberCount: 42,
        createdAt: DateTime.now().subtract(const Duration(days: 80)),
        category: 'Marriage',
      ),
    ];
  }

  // ============== Friend Methods ==============

  Future<List<Friend>> getFriends() async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockFriends);
  }

  Future<List<Friend>> getSuggestedFriends() async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_suggestedFriends);
  }

  Future<List<FriendRequest>> getFriendRequests() async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_pendingRequests);
  }

  Future<bool> sendFriendRequest(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Implement with Supabase
    return true;
  }

  Future<bool> acceptFriendRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _pendingRequests = _pendingRequests.where((r) => r.id != requestId).toList();
    return true;
  }

  Future<bool> declineFriendRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _pendingRequests = _pendingRequests.where((r) => r.id != requestId).toList();
    return true;
  }

  Future<bool> removeFriend(String friendId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Implement with Supabase
    return true;
  }

  // ============== Activity Methods ==============

  Future<List<FriendActivity>> getActivityFeed() async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockActivities);
  }

  // ============== Intention Methods ==============

  Future<List<SharedIntention>> getSharedIntentions() async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockIntentions);
  }

  Future<SharedIntention?> createIntention(String content) async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 500));

    final intention = SharedIntention(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      author: const Friend(id: 'me', name: 'You'),
      content: content,
      createdAt: DateTime.now(),
    );

    _mockIntentions.insert(0, intention);
    return intention;
  }

  Future<bool> prayForIntention(String intentionId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockIntentions.indexWhere((i) => i.id == intentionId);
    if (index != -1) {
      final intention = _mockIntentions[index];
      _mockIntentions[index] = intention.copyWith(
        prayerCount: intention.prayerCount + 1,
        hasPrayed: true,
      );
      return true;
    }
    return false;
  }

  Future<bool> commentOnIntention(String intentionId, String comment) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Implement with Supabase
    return true;
  }

  // ============== Group Methods ==============

  Future<List<PrayerGroup>> getMyGroups() async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockGroups);
  }

  Future<List<PrayerGroup>> discoverGroups({String? category}) async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 300));

    if (category != null && category.isNotEmpty) {
      return _discoverGroups.where((g) => g.category == category).toList();
    }
    return List.from(_discoverGroups);
  }

  Future<PrayerGroup?> getGroupDetails(String groupId) async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 300));

    final allGroups = [..._mockGroups, ..._discoverGroups];
    try {
      return allGroups.firstWhere((g) => g.id == groupId);
    } catch (_) {
      return null;
    }
  }

  Future<PrayerGroup?> createGroup({
    required String name,
    required String description,
    required GroupPrivacy privacy,
    String? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final group = PrayerGroup(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      privacy: privacy,
      category: category,
      createdAt: DateTime.now(),
      isMember: true,
      isAdmin: true,
      memberCount: 1,
    );

    _mockGroups.add(group);
    return group;
  }

  Future<bool> joinGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _discoverGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _discoverGroups[index];
      if (group.privacy == GroupPrivacy.public) {
        _discoverGroups.removeAt(index);
        _mockGroups.add(group.copyWith(
          isMember: true,
          memberCount: group.memberCount + 1,
        ));
      } else {
        _discoverGroups[index] = group.copyWith(hasPendingRequest: true);
      }
      return true;
    }
    return false;
  }

  Future<bool> leaveGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _mockGroups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _mockGroups[index];
      _mockGroups.removeAt(index);
      _discoverGroups.add(group.copyWith(
        isMember: false,
        memberCount: group.memberCount - 1,
      ));
      return true;
    }
    return false;
  }

  Future<List<SharedIntention>> getGroupIntentions(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Return a subset of intentions for the group
    return _mockIntentions.take(3).toList();
  }

  // ============== Search Methods ==============

  Future<List<Friend>> searchUsers(String query) async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 300));

    final q = query.toLowerCase();
    final all = [..._mockFriends, ..._suggestedFriends];
    return all.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  Future<List<PrayerGroup>> searchGroups(String query) async {
    _initMockData();
    await Future.delayed(const Duration(milliseconds: 300));

    final q = query.toLowerCase();
    final all = [..._mockGroups, ..._discoverGroups];
    return all.where((g) =>
      g.name.toLowerCase().contains(q) ||
      g.description.toLowerCase().contains(q)
    ).toList();
  }
}
