import 'package:quick_church/core/error/failures.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer_session.dart';

/// Abstract repository interface for Prayer operations.
///
/// This interface defines the contract for data operations related to prayers.
/// The implementation details are handled in the data layer.
abstract class IPrayerRepository {
  /// Retrieves all prayers.
  ///
  /// Returns a [List<Prayer>] on success or a [Failure] on error.
  Future<({List<Prayer>? data, Failure? failure})> getAllPrayers();

  /// Retrieves prayers filtered by status.
  ///
  /// Returns a [List<Prayer>] on success or a [Failure] on error.
  Future<({List<Prayer>? data, Failure? failure})> getPrayersByStatus(
    PrayerStatus status,
  );

  /// Retrieves a single prayer by its ID.
  ///
  /// Returns a [Prayer] on success or a [Failure] on error.
  Future<({Prayer? data, Failure? failure})> getPrayerById(String id);

  /// Creates a new prayer.
  ///
  /// Returns the created [Prayer] on success or a [Failure] on error.
  Future<({Prayer? data, Failure? failure})> createPrayer(Prayer prayer);

  /// Updates an existing prayer.
  ///
  /// Returns the updated [Prayer] on success or a [Failure] on error.
  Future<({Prayer? data, Failure? failure})> updatePrayer(Prayer prayer);

  /// Deletes a prayer by its ID.
  ///
  /// Returns `true` on success or a [Failure] on error.
  Future<({bool? data, Failure? failure})> deletePrayer(String id);

  /// Increments the prayer count for a specific prayer.
  ///
  /// Returns the updated [Prayer] on success or a [Failure] on error.
  Future<({Prayer? data, Failure? failure})> incrementPrayerCount(String id);

  /// Marks a prayer as answered.
  ///
  /// Returns the updated [Prayer] on success or a [Failure] on error.
  Future<({Prayer? data, Failure? failure})> markAsAnswered(String id);

  /// Marks a prayer as active (reactivates an answered prayer).
  ///
  /// Returns the updated [Prayer] on success or a [Failure] on error.
  Future<({Prayer? data, Failure? failure})> markAsActive(String id);

  /// Updates the testimony for an answered prayer.
  ///
  /// Returns the updated [Prayer] on success or a [Failure] on error.
  /// Set [isPublic] to true to share the testimony with the community.
  Future<({Prayer? data, Failure? failure})> updateTestimony(
    String id,
    String testimony, {
    bool isPublic = false,
  });

  /// Searches prayers by title or description.
  ///
  /// Returns a [List<Prayer>] on success or a [Failure] on error.
  Future<({List<Prayer>? data, Failure? failure})> searchPrayers(String query);

  /// Toggles the lock status of a prayer.
  ///
  /// Returns the updated [Prayer] on success or a [Failure] on error.
  Future<({Prayer? data, Failure? failure})> toggleLock(String id);

  // ============================================================================
  // PRAYER PERSISTENCE / SESSION LOGGING
  // ============================================================================

  /// Records a prayer session for a specific prayer (from Sacred Time or manual).
  /// This increments the prayer's times_prayed counter and logs the session.
  ///
  /// Returns the updated [Prayer] with new count on success or a [Failure] on error.
  Future<({Prayer? data, Failure? failure})> recordPrayerSession({
    required String prayerId,
    required int durationMinutes,
    int? actualDurationSeconds,
    DateTime? prayedAt,
    bool isManual = false,
    String? notes,
  });

  /// Gets the prayer history (all sessions) for a specific prayer.
  ///
  /// Returns a [List<PrayerSession>] on success or a [Failure] on error.
  Future<({List<PrayerSession>? data, Failure? failure})> getPrayerHistory(
    String prayerId, {
    int limit = 20,
    int offset = 0,
  });

  /// Gets persistence stats for a prayer (total sessions, total time, etc.).
  ///
  /// Returns a Map with stats on success or a [Failure] on error.
  Future<({Map<String, dynamic>? data, Failure? failure})> getPrayerPersistenceStats(
    String prayerId,
  );
}
