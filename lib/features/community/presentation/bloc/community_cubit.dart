import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/community_repository.dart';
import '../../domain/entities/friend.dart';
import '../../domain/entities/friend_activity.dart';
import '../../domain/entities/shared_intention.dart';
import '../../domain/entities/prayer_group.dart';
import 'community_state.dart';

/// Cubit for managing Community state.
class CommunityCubit extends Cubit<CommunityState> {
  final CommunityRepository _repository;

  CommunityCubit({CommunityRepository? repository})
      : _repository = repository ?? CommunityRepository(),
        super(const CommunityState());

  /// Load all community data.
  Future<void> loadAll() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final results = await Future.wait([
        _repository.getFriends(),
        _repository.getSuggestedFriends(),
        _repository.getFriendRequests(),
        _repository.getActivityFeed(),
        _repository.getSharedIntentions(),
        _repository.getMyGroups(),
        _repository.discoverGroups(),
      ]);

      emit(state.copyWith(
        isLoading: false,
        friends: (results[0] as List).cast<Friend>(),
        suggestedFriends: (results[1] as List).cast<Friend>(),
        friendRequests: (results[2] as List).cast<FriendRequest>(),
        activities: (results[3] as List).cast<FriendActivity>(),
        intentions: (results[4] as List).cast<SharedIntention>(),
        myGroups: (results[5] as List).cast<PrayerGroup>(),
        discoverGroups: (results[6] as List).cast<PrayerGroup>(),
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  // ============== Friend Methods ==============

  Future<void> loadFriends() async {
    try {
      final friends = await _repository.getFriends();
      final suggested = await _repository.getSuggestedFriends();
      final requests = await _repository.getFriendRequests();
      emit(state.copyWith(
        friends: friends,
        suggestedFriends: suggested,
        friendRequests: requests,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> sendFriendRequest(String userId) async {
    try {
      await _repository.sendFriendRequest(userId);
      // Remove from suggestions
      final updated = state.suggestedFriends.where((f) => f.id != userId).toList();
      emit(state.copyWith(suggestedFriends: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _repository.acceptFriendRequest(requestId);
      final request = state.friendRequests.firstWhere((r) => r.id == requestId);
      final updatedRequests = state.friendRequests.where((r) => r.id != requestId).toList();
      final updatedFriends = [...state.friends, request.from];
      emit(state.copyWith(
        friendRequests: updatedRequests,
        friends: updatedFriends,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _repository.declineFriendRequest(requestId);
      final updatedRequests = state.friendRequests.where((r) => r.id != requestId).toList();
      emit(state.copyWith(friendRequests: updatedRequests));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // ============== Activity Methods ==============

  Future<void> loadActivityFeed() async {
    try {
      final activities = await _repository.getActivityFeed();
      emit(state.copyWith(activities: activities));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // ============== Intention Methods ==============

  Future<void> loadIntentions() async {
    try {
      final intentions = await _repository.getSharedIntentions();
      emit(state.copyWith(intentions: intentions));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> createIntention(String content) async {
    try {
      final intention = await _repository.createIntention(content);
      if (intention != null) {
        emit(state.copyWith(intentions: [intention, ...state.intentions]));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> prayForIntention(String intentionId) async {
    try {
      await _repository.prayForIntention(intentionId);
      final updated = state.intentions.map((i) {
        if (i.id == intentionId) {
          return i.copyWith(
            prayerCount: i.prayerCount + 1,
            hasPrayed: true,
          );
        }
        return i;
      }).toList();
      emit(state.copyWith(intentions: updated));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // ============== Group Methods ==============

  Future<void> loadMyGroups() async {
    try {
      final groups = await _repository.getMyGroups();
      emit(state.copyWith(myGroups: groups));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadDiscoverGroups({String? category}) async {
    try {
      final groups = await _repository.discoverGroups(category: category);
      emit(state.copyWith(discoverGroups: groups));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> selectGroup(String groupId) async {
    try {
      final group = await _repository.getGroupDetails(groupId);
      emit(state.copyWith(selectedGroup: group));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void clearSelectedGroup() {
    emit(state.copyWith(clearSelectedGroup: true));
  }

  Future<void> createGroup({
    required String name,
    required String description,
    required GroupPrivacy privacy,
    String? category,
  }) async {
    try {
      final group = await _repository.createGroup(
        name: name,
        description: description,
        privacy: privacy,
        category: category,
      );
      if (group != null) {
        emit(state.copyWith(myGroups: [...state.myGroups, group]));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> joinGroup(String groupId) async {
    try {
      await _repository.joinGroup(groupId);
      // Refresh both lists
      await Future.wait([loadMyGroups(), loadDiscoverGroups()]);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await _repository.leaveGroup(groupId);
      // Refresh both lists
      await Future.wait([loadMyGroups(), loadDiscoverGroups()]);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // ============== Search Methods ==============

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      await loadFriends();
      return;
    }
    try {
      final results = await _repository.searchUsers(query);
      emit(state.copyWith(suggestedFriends: results));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> searchGroups(String query) async {
    if (query.isEmpty) {
      await loadDiscoverGroups();
      return;
    }
    try {
      final results = await _repository.searchGroups(query);
      emit(state.copyWith(discoverGroups: results));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
