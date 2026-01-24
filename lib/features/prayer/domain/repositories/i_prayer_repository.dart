import 'package:quick_church/core/error/failures.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';

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
  Future<({Prayer? data, Failure? failure})> updateTestimony(
    String id,
    String testimony,
  );

  /// Searches prayers by title or description.
  ///
  /// Returns a [List<Prayer>] on success or a [Failure] on error.
  Future<({List<Prayer>? data, Failure? failure})> searchPrayers(String query);

  /// Toggles the lock status of a prayer.
  ///
  /// Returns the updated [Prayer] on success or a [Failure] on error.
  Future<({Prayer? data, Failure? failure})> toggleLock(String id);
}
