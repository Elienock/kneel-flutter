import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/testimony.dart';
import '../../domain/repositories/i_testimony_repository.dart';
import 'testimony_state.dart';

/// Cubit for managing testimony vault state.
@injectable
class TestimonyCubit extends Cubit<TestimonyState> {
  final ITestimonyRepository _repository;
  StreamSubscription<List<Testimony>>? _testimoniesSubscription;
  StreamSubscription<TestimonyStats>? _statsSubscription;

  TestimonyCubit(this._repository) : super(const TestimonyState());

  /// Load all testimonies and stats.
  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final results = await Future.wait([
        _repository.getTestimonies(),
        _repository.getStats(),
      ]);

      final testimonies = results[0] as List<Testimony>;
      final stats = results[1] as TestimonyStats;

      emit(state.copyWith(
        testimonies: testimonies,
        stats: stats,
        isLoading: false,
      ));

      // Start watching for real-time updates
      _startWatching();
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load testimonies: $e',
      ));
    }
  }

  void _startWatching() {
    _testimoniesSubscription?.cancel();
    _statsSubscription?.cancel();

    _testimoniesSubscription = _repository.watchTestimonies().listen(
      (testimonies) {
        emit(state.copyWith(testimonies: testimonies));
      },
      onError: (e) {
        // Silent fail for stream errors
      },
    );

    _statsSubscription = _repository.watchStats().listen(
      (stats) {
        emit(state.copyWith(stats: stats));
      },
      onError: (e) {
        // Silent fail for stream errors
      },
    );
  }

  /// Create a standalone testimony.
  Future<void> createTestimony({
    required String title,
    required String story,
    DateTime? eventDate,
    bool isPublic = false,
    String? imageUrl,
  }) async {
    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final testimony = await _repository.createTestimony(
        type: TestimonyType.standalone,
        title: title,
        story: story,
        eventDate: eventDate,
        isPublic: isPublic,
        imageUrl: imageUrl,
      );

      HapticFeedback.mediumImpact();

      final updatedList = [testimony, ...state.testimonies];
      emit(state.copyWith(
        testimonies: updatedList,
        isSaving: false,
        successMessage: 'Testimony saved!',
      ));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        error: 'Failed to save testimony: $e',
      ));
    }
  }

  /// Create a gratitude entry.
  Future<void> createGratitude({
    required String title,
    String? story,
    GratitudeCategory? category,
    DateTime? eventDate,
    bool isPublic = false,
  }) async {
    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final testimony = await _repository.createTestimony(
        type: TestimonyType.gratitude,
        title: title,
        story: story,
        eventDate: eventDate ?? DateTime.now(),
        isPublic: isPublic,
        category: category,
      );

      HapticFeedback.mediumImpact();

      final updatedList = [testimony, ...state.testimonies];
      emit(state.copyWith(
        testimonies: updatedList,
        isSaving: false,
        successMessage: 'Gratitude recorded!',
      ));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        error: 'Failed to save gratitude: $e',
      ));
    }
  }

  /// Create an answered prayer testimony (synced from Prayer feature).
  Future<void> createAnsweredPrayerTestimony({
    required String prayerId,
    required String prayerTitle,
    required String story,
    int prayerCount = 0,
    int? daysToAnswer,
    DateTime? answeredAt,
    bool isPublic = false,
    String? imageUrl,
  }) async {
    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final testimony = await _repository.createTestimony(
        type: TestimonyType.answeredPrayer,
        title: prayerTitle,
        story: story,
        prayerId: prayerId,
        prayerTitle: prayerTitle,
        prayerCount: prayerCount,
        daysToAnswer: daysToAnswer,
        eventDate: answeredAt,
        isPublic: isPublic,
        imageUrl: imageUrl,
      );

      HapticFeedback.mediumImpact();

      final updatedList = [testimony, ...state.testimonies];
      emit(state.copyWith(
        testimonies: updatedList,
        isSaving: false,
        successMessage: isPublic
            ? 'Testimony shared with community!'
            : 'Testimony saved!',
      ));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        error: 'Failed to save testimony: $e',
      ));
    }
  }

  /// Update a testimony.
  Future<void> updateTestimony(Testimony testimony) async {
    try {
      final updated = await _repository.updateTestimony(testimony);

      final updatedList = state.testimonies.map((t) {
        return t.id == updated.id ? updated : t;
      }).toList();

      emit(state.copyWith(
        testimonies: updatedList,
        successMessage: 'Testimony updated',
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update testimony: $e'));
    }
  }

  /// Toggle testimony privacy.
  Future<void> togglePrivacy(String id) async {
    try {
      final testimony = state.testimonies.firstWhere((t) => t.id == id);
      final newPublicState = !testimony.isPublic;

      await _repository.updatePrivacy(id, newPublicState);

      final updatedList = state.testimonies.map((t) {
        return t.id == id ? t.copyWith(isPublic: newPublicState) : t;
      }).toList();

      emit(state.copyWith(
        testimonies: updatedList,
        successMessage: newPublicState
            ? 'Testimony shared publicly'
            : 'Testimony is now private',
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update privacy: $e'));
    }
  }

  /// Delete a testimony.
  Future<void> deleteTestimony(String id) async {
    try {
      await _repository.deleteTestimony(id);

      final updatedList = state.testimonies.where((t) => t.id != id).toList();

      emit(state.copyWith(
        testimonies: updatedList,
        successMessage: 'Testimony deleted',
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete testimony: $e'));
    }
  }

  /// Celebrate a public testimony.
  Future<void> celebrate(String id) async {
    try {
      await _repository.celebrateTestimony(id);

      // Optimistically update the count
      final updatedList = state.testimonies.map((t) {
        return t.id == id
            ? t.copyWith(celebrationCount: t.celebrationCount + 1)
            : t;
      }).toList();

      emit(state.copyWith(testimonies: updatedList));

      HapticFeedback.lightImpact();
    } catch (e) {
      // Silent fail for celebration
    }
  }

  /// Clear success message.
  void clearMessage() {
    emit(state.copyWith(clearSuccessMessage: true));
  }

  /// Clear error.
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  /// Filter testimonies by type.
  List<Testimony> getByType(TestimonyType type) {
    return state.testimonies.where((t) => t.type == type).toList();
  }

  /// Get all gratitude entries.
  List<Testimony> get gratitudeEntries => getByType(TestimonyType.gratitude);

  /// Get all standalone testimonies.
  List<Testimony> get standaloneTestimonies => getByType(TestimonyType.standalone);

  /// Get all answered prayer testimonies.
  List<Testimony> get answeredPrayerTestimonies =>
      getByType(TestimonyType.answeredPrayer);

  @override
  Future<void> close() {
    _testimoniesSubscription?.cancel();
    _statsSubscription?.cancel();
    return super.close();
  }
}
