import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quick_church/features/pulpit/data/repositories/pulpit_repository.dart';
import 'package:quick_church/features/pulpit/domain/entities/pulpit_prayer_group.dart';
import 'package:quick_church/features/pulpit/presentation/bloc/pulpit_state.dart';

/// Cubit for managing pulpit prayer groups.
class PulpitCubit extends Cubit<PulpitState> {
  final PulpitRepository _repository;

  PulpitCubit({PulpitRepository? repository})
      : _repository = repository ?? PulpitRepository(),
        super(const PulpitState());

  /// Load all prayer groups.
  Future<void> loadGroups() async {
    emit(state.copyWith(status: PulpitStatus.loading));

    try {
      final groups = await _repository.getGroups();
      emit(state.copyWith(
        status: PulpitStatus.loaded,
        groups: groups,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PulpitStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Load a specific group with its prayer points.
  Future<PulpitPrayerGroup?> loadGroupWithPoints(String groupId) async {
    try {
      final group = await _repository.getGroupWithPoints(groupId);
      if (group != null) {
        emit(state.copyWith(selectedGroup: group));
      }
      return group;
    } catch (e) {
      emit(state.copyWith(
        status: PulpitStatus.error,
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  /// Create a new prayer group.
  Future<PulpitPrayerGroup?> createGroup({
    required String title,
    String? description,
    bool autoAdvance = false,
    int secondsPerPoint = 300,
  }) async {
    try {
      final group = await _repository.createGroup(
        title: title,
        description: description,
        autoAdvance: autoAdvance,
        secondsPerPoint: secondsPerPoint,
      );

      final updatedGroups = [group, ...state.groups];
      emit(state.copyWith(
        groups: updatedGroups,
        selectedGroup: group,
      ));

      return group;
    } catch (e) {
      emit(state.copyWith(
        status: PulpitStatus.error,
        errorMessage: e.toString(),
      ));
      return null;
    }
  }

  /// Update a prayer group.
  Future<void> updateGroup(PulpitPrayerGroup group) async {
    try {
      final updated = await _repository.updateGroup(group);

      final updatedGroups = state.groups.map((g) {
        return g.id == updated.id ? updated : g;
      }).toList();

      emit(state.copyWith(
        groups: updatedGroups,
        selectedGroup: state.selectedGroup?.id == updated.id
            ? updated.copyWith(points: state.selectedGroup?.points ?? [])
            : state.selectedGroup,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PulpitStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Delete a prayer group.
  Future<void> deleteGroup(String groupId) async {
    try {
      await _repository.deleteGroup(groupId);

      final updatedGroups = state.groups.where((g) => g.id != groupId).toList();
      emit(state.copyWith(
        groups: updatedGroups,
        clearSelectedGroup: state.selectedGroup?.id == groupId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PulpitStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Mark group as used after a session.
  Future<void> markGroupUsed(String groupId) async {
    try {
      await _repository.incrementGroupUsage(groupId);
      // Refresh groups to get updated count
      await loadGroups();
    } catch (e) {
      // Non-critical, don't emit error
    }
  }

  /// Add a prayer point to the selected group.
  Future<void> addPoint({
    required String title,
    String? description,
    List<ScriptureReference> scriptures = const [],
  }) async {
    if (state.selectedGroup == null) return;

    try {
      final point = await _repository.addPoint(
        groupId: state.selectedGroup!.id,
        title: title,
        description: description,
        scriptures: scriptures,
      );

      final updatedPoints = [...state.selectedGroup!.points, point];
      final updatedGroup = state.selectedGroup!.copyWith(points: updatedPoints);

      emit(state.copyWith(selectedGroup: updatedGroup));
    } catch (e) {
      emit(state.copyWith(
        status: PulpitStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Update a prayer point.
  Future<void> updatePoint(PulpitPrayerPoint point) async {
    if (state.selectedGroup == null) return;

    try {
      final updated = await _repository.updatePoint(point);

      final updatedPoints = state.selectedGroup!.points.map((p) {
        return p.id == updated.id ? updated : p;
      }).toList();

      final updatedGroup = state.selectedGroup!.copyWith(points: updatedPoints);
      emit(state.copyWith(selectedGroup: updatedGroup));
    } catch (e) {
      emit(state.copyWith(
        status: PulpitStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Delete a prayer point.
  Future<void> deletePoint(String pointId) async {
    if (state.selectedGroup == null) return;

    try {
      await _repository.deletePoint(pointId);

      final updatedPoints = state.selectedGroup!.points
          .where((p) => p.id != pointId)
          .toList();

      final updatedGroup = state.selectedGroup!.copyWith(points: updatedPoints);
      emit(state.copyWith(selectedGroup: updatedGroup));
    } catch (e) {
      emit(state.copyWith(
        status: PulpitStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Reorder prayer points.
  Future<void> reorderPoints(int oldIndex, int newIndex) async {
    if (state.selectedGroup == null) return;

    // Adjust index for removal
    if (newIndex > oldIndex) newIndex--;

    final points = List<PulpitPrayerPoint>.from(state.selectedGroup!.points);
    final item = points.removeAt(oldIndex);
    points.insert(newIndex, item);

    // Update local state immediately for smooth UX
    final updatedGroup = state.selectedGroup!.copyWith(points: points);
    emit(state.copyWith(selectedGroup: updatedGroup));

    // Persist to database
    try {
      await _repository.reorderPoints(points);
    } catch (e) {
      // Revert on error
      await loadGroupWithPoints(state.selectedGroup!.id);
    }
  }

  /// Clear selected group.
  void clearSelectedGroup() {
    emit(state.copyWith(clearSelectedGroup: true));
  }
}
