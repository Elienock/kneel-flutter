import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quick_church/core/usecases/usecase.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer_session.dart';
import 'package:quick_church/features/prayer/domain/repositories/i_prayer_repository.dart';
import 'package:quick_church/features/prayer/domain/usecases/add_prayer.dart';
import 'package:quick_church/features/prayer/domain/usecases/delete_prayer.dart';
import 'package:quick_church/features/prayer/domain/usecases/get_prayers.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';

/// Cubit for managing prayer-related state.
@injectable
class PrayerCubit extends Cubit<PrayerState> {
  final GetPrayers _getPrayers;
  final AddPrayer _addPrayer;
  final DeletePrayer _deletePrayer;
  final IPrayerRepository _repository;

  PrayerCubit(
    this._getPrayers,
    this._addPrayer,
    this._deletePrayer,
    this._repository,
  ) : super(const PrayerInitial());

  /// Loads all prayers from the repository.
  Future<void> loadPrayers() async {
    emit(const PrayerLoading());

    final result = await _getPrayers(const NoParams());

    if (result.failure != null) {
      emit(PrayerError(result.failure!.message));
    } else {
      emit(PrayerLoaded(result.data ?? []));
    }
  }

  /// Adds a new prayer with the given parameters.
  Future<void> addPrayer({
    required String title,
    required String description,
    String? requesterName,
    PrayerPriority priority = PrayerPriority.medium,
    bool isLocked = false,
    List<String> tags = const [],
  }) async {
    final currentPrayers = state is PrayerLoaded
        ? (state as PrayerLoaded).prayers
        : <Prayer>[];

    emit(const PrayerLoading());

    final params = AddPrayerParams(
      title: title,
      description: description,
      requesterName: requesterName,
      priority: priority,
      isLocked: isLocked,
      tags: tags,
    );

    final result = await _addPrayer(params);

    if (result.failure != null) {
      emit(PrayerError(result.failure!.message));
    } else {
      HapticFeedback.mediumImpact();
      // Reload prayers and show success message
      final refreshResult = await _getPrayers(const NoParams());
      if (refreshResult.failure != null) {
        emit(PrayerLoaded(
          [result.data!, ...currentPrayers],
          successMessage: 'Prayer added successfully',
        ));
      } else {
        emit(PrayerLoaded(
          refreshResult.data ?? [],
          successMessage: 'Prayer added successfully',
        ));
      }
    }
  }

  /// Deletes a prayer by its ID.
  Future<void> deletePrayer(String id) async {
    final currentPrayers = state is PrayerLoaded
        ? (state as PrayerLoaded).prayers
        : <Prayer>[];

    // Optimistic update - remove from UI immediately
    final updatedPrayers = currentPrayers.where((p) => p.id != id).toList();
    emit(PrayerLoaded(updatedPrayers));

    final result = await _deletePrayer(DeletePrayerParams(id: id));

    if (result.failure != null) {
      // Revert on failure
      emit(PrayerLoaded(currentPrayers));
      emit(PrayerError(result.failure!.message));
    } else {
      HapticFeedback.mediumImpact();
      emit(PrayerLoaded(
        updatedPrayers,
        successMessage: 'Prayer deleted',
      ));
    }
  }

  /// Clears the current success message.
  void clearMessage() {
    if (state is PrayerLoaded) {
      emit((state as PrayerLoaded).clearMessage());
    }
  }

  /// Increments the prayer count for a prayer.
  /// Allows multiple clicks with haptic pulse and "Amen" feedback.
  Future<void> incrementPrayerCount(String id) async {
    final currentPrayers = state is PrayerLoaded
        ? (state as PrayerLoaded).prayers
        : <Prayer>[];

    // Haptic pulse on each prayer
    HapticFeedback.mediumImpact();

    final result = await _repository.incrementPrayerCount(id);

    if (result.failure != null) {
      emit(PrayerError(result.failure!.message));
    } else {
      // Update local state - globally synced across all tabs
      final updatedPrayers = currentPrayers.map((p) {
        if (p.id == id) {
          return result.data!;
        }
        return p;
      }).toList();

      emit(PrayerLoaded(
        updatedPrayers,
        successMessage: 'Amen',
      ));
    }
  }

  /// Marks a prayer as answered.
  Future<void> markAsAnswered(String id) async {
    final currentPrayers = state is PrayerLoaded
        ? (state as PrayerLoaded).prayers
        : <Prayer>[];

    final result = await _repository.markAsAnswered(id);

    if (result.failure != null) {
      emit(PrayerError(result.failure!.message));
    } else {
      // Update local state
      final updatedPrayers = currentPrayers.map((p) {
        if (p.id == id) {
          return result.data!;
        }
        return p;
      }).toList();

      emit(PrayerLoaded(
        updatedPrayers,
        successMessage: 'Praise God! Prayer marked as answered',
      ));
    }
  }

  /// Marks a prayer as active (reactivates).
  Future<void> markAsActive(String id) async {
    final currentPrayers = state is PrayerLoaded
        ? (state as PrayerLoaded).prayers
        : <Prayer>[];

    final result = await _repository.markAsActive(id);

    if (result.failure != null) {
      emit(PrayerError(result.failure!.message));
    } else {
      // Update local state
      final updatedPrayers = currentPrayers.map((p) {
        if (p.id == id) {
          return result.data!;
        }
        return p;
      }).toList();

      emit(PrayerLoaded(
        updatedPrayers,
        successMessage: 'Prayer reactivated',
      ));
    }
  }

  /// Updates the testimony for an answered prayer.
  /// Set [isPublic] to true to share the testimony with the community.
  Future<void> updateTestimony(
    String id,
    String testimony, {
    bool isPublic = false,
  }) async {
    final currentPrayers = state is PrayerLoaded
        ? (state as PrayerLoaded).prayers
        : <Prayer>[];

    final result = await _repository.updateTestimony(
      id,
      testimony,
      isPublic: isPublic,
    );

    if (result.failure != null) {
      emit(PrayerError(result.failure!.message));
    } else {
      HapticFeedback.mediumImpact();
      // Update local state
      final updatedPrayers = currentPrayers.map((p) {
        if (p.id == id) {
          return result.data!;
        }
        return p;
      }).toList();

      emit(PrayerLoaded(
        updatedPrayers,
        successMessage: isPublic
          ? 'Testimony shared with community!'
          : 'Testimony saved',
      ));
    }
  }

  /// Toggles the lock status of a prayer.
  Future<void> toggleLock(String id) async {
    final currentPrayers = state is PrayerLoaded
        ? (state as PrayerLoaded).prayers
        : <Prayer>[];

    final result = await _repository.toggleLock(id);

    if (result.failure != null) {
      emit(PrayerError(result.failure!.message));
    } else {
      HapticFeedback.mediumImpact();
      // Update local state
      final updatedPrayers = currentPrayers.map((p) {
        if (p.id == id) {
          return result.data!;
        }
        return p;
      }).toList();

      final isNowLocked = result.data!.isLocked;
      emit(PrayerLoaded(
        updatedPrayers,
        successMessage: isNowLocked ? 'Prayer locked' : 'Prayer unlocked',
      ));
    }
  }

  /// Updates a prayer with new values.
  Future<void> updatePrayer(Prayer prayer) async {
    final currentPrayers = state is PrayerLoaded
        ? (state as PrayerLoaded).prayers
        : <Prayer>[];

    final result = await _repository.updatePrayer(prayer);

    if (result.failure != null) {
      emit(PrayerError(result.failure!.message));
    } else {
      HapticFeedback.mediumImpact();
      // Update local state
      final updatedPrayers = currentPrayers.map((p) {
        if (p.id == prayer.id) {
          return result.data!;
        }
        return p;
      }).toList();

      emit(PrayerLoaded(
        updatedPrayers,
        successMessage: 'Prayer updated',
      ));
    }
  }

  /// Searches prayers by query.
  List<Prayer> searchPrayers(String query) {
    if (state is! PrayerLoaded) return [];

    final prayers = (state as PrayerLoaded).prayers;
    if (query.isEmpty) return prayers;

    final lowerQuery = query.toLowerCase();
    return prayers.where((p) {
      return p.title.toLowerCase().contains(lowerQuery) ||
          p.description.toLowerCase().contains(lowerQuery) ||
          p.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // ============================================================================
  // PRAYER PERSISTENCE / SESSION LOGGING
  // These track individual prayer sessions for the "Prayed Xх" badge
  // ============================================================================

  /// Records a prayer session from Sacred Time or other timed prayer.
  /// This increments the prayer's count and logs the session for history.
  /// Returns the new total times prayed.
  Future<int?> recordPrayerSession({
    required String prayerId,
    required int durationMinutes,
    int? actualDurationSeconds,
    DateTime? prayedAt,
    String? notes,
  }) async {
    final currentPrayers = state is PrayerLoaded
        ? (state as PrayerLoaded).prayers
        : <Prayer>[];

    final result = await _repository.recordPrayerSession(
      prayerId: prayerId,
      durationMinutes: durationMinutes,
      actualDurationSeconds: actualDurationSeconds,
      prayedAt: prayedAt,
      isManual: false,
      notes: notes,
    );

    if (result.failure != null) {
      return null;
    }

    // Update local state with new prayer count
    final updatedPrayer = result.data!;
    final updatedPrayers = currentPrayers.map((p) {
      if (p.id == prayerId) return updatedPrayer;
      return p;
    }).toList();

    emit(PrayerLoaded(
      updatedPrayers,
      successMessage: "Session recorded. You've lifted this up ${updatedPrayer.prayerCount} times.",
    ));

    return updatedPrayer.prayerCount;
  }

  /// Logs a manual prayer session (for offline/unreported prayers).
  /// This allows users to record prayers done without the app.
  Future<int?> logManualPrayer({
    required String prayerId,
    required int durationMinutes,
    required DateTime prayedAt,
    String? notes,
  }) async {
    final currentPrayers = state is PrayerLoaded
        ? (state as PrayerLoaded).prayers
        : <Prayer>[];

    HapticFeedback.mediumImpact();

    final result = await _repository.recordPrayerSession(
      prayerId: prayerId,
      durationMinutes: durationMinutes,
      prayedAt: prayedAt,
      isManual: true,
      notes: notes,
    );

    if (result.failure != null) {
      emit(PrayerError('Failed to log prayer: ${result.failure!.message}'));
      return null;
    }

    // Update local state with new prayer count
    final updatedPrayer = result.data!;
    final updatedPrayers = currentPrayers.map((p) {
      if (p.id == prayerId) return updatedPrayer;
      return p;
    }).toList();

    emit(PrayerLoaded(
      updatedPrayers,
      successMessage: 'Prayer logged! Total: ${updatedPrayer.prayerCount} times',
    ));

    return updatedPrayer.prayerCount;
  }

  /// Gets the prayer history (all sessions) for a specific prayer.
  Future<List<PrayerSession>> getPrayerHistory(String prayerId) async {
    final result = await _repository.getPrayerHistory(prayerId);
    return result.data ?? [];
  }

  /// Gets persistence stats for a prayer.
  Future<Map<String, dynamic>?> getPrayerPersistenceStats(String prayerId) async {
    final result = await _repository.getPrayerPersistenceStats(prayerId);
    return result.data;
  }
}
