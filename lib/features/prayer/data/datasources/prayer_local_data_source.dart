import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:quick_church/core/error/exceptions.dart';
import 'package:quick_church/features/prayer/data/models/prayer_model.dart';

/// Abstract interface for local prayer data operations.
abstract class PrayerLocalDataSource {
  /// Gets all prayers from local storage.
  Future<List<PrayerModel>> getAllPrayers();

  /// Gets prayers filtered by status.
  Future<List<PrayerModel>> getPrayersByStatus(PrayerStatusModel status);

  /// Gets a single prayer by ID.
  Future<PrayerModel> getPrayerById(String id);

  /// Saves a new prayer to local storage.
  Future<PrayerModel> createPrayer(PrayerModel prayer);

  /// Updates an existing prayer.
  Future<PrayerModel> updatePrayer(PrayerModel prayer);

  /// Deletes a prayer by ID.
  Future<bool> deletePrayer(String id);

  /// Searches prayers by query string.
  Future<List<PrayerModel>> searchPrayers(String query);
}

/// Implementation of [PrayerLocalDataSource] using Hive.
@LazySingleton(as: PrayerLocalDataSource)
class PrayerLocalDataSourceImpl implements PrayerLocalDataSource {
  static const String boxName = 'prayers';

  final Box<PrayerModel> _box;

  PrayerLocalDataSourceImpl(this._box);

  @override
  Future<List<PrayerModel>> getAllPrayers() async {
    try {
      final prayers = _box.values.toList();
      prayers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return prayers;
    } catch (e) {
      throw CacheException(message: 'Failed to get prayers: $e');
    }
  }

  @override
  Future<List<PrayerModel>> getPrayersByStatus(PrayerStatusModel status) async {
    try {
      final prayers = _box.values
          .where((prayer) => prayer.status == status)
          .toList();
      prayers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return prayers;
    } catch (e) {
      throw CacheException(message: 'Failed to get prayers by status: $e');
    }
  }

  @override
  Future<PrayerModel> getPrayerById(String id) async {
    try {
      final prayer = _box.get(id);
      if (prayer == null) {
        throw NotFoundException(message: 'Prayer with id $id not found');
      }
      return prayer;
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw CacheException(message: 'Failed to get prayer: $e');
    }
  }

  @override
  Future<PrayerModel> createPrayer(PrayerModel prayer) async {
    try {
      await _box.put(prayer.id, prayer);
      return prayer;
    } catch (e) {
      throw CacheException(message: 'Failed to create prayer: $e');
    }
  }

  @override
  Future<PrayerModel> updatePrayer(PrayerModel prayer) async {
    try {
      if (!_box.containsKey(prayer.id)) {
        throw NotFoundException(message: 'Prayer with id ${prayer.id} not found');
      }
      await _box.put(prayer.id, prayer);
      return prayer;
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw CacheException(message: 'Failed to update prayer: $e');
    }
  }

  @override
  Future<bool> deletePrayer(String id) async {
    try {
      if (!_box.containsKey(id)) {
        throw NotFoundException(message: 'Prayer with id $id not found');
      }
      await _box.delete(id);
      return true;
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw CacheException(message: 'Failed to delete prayer: $e');
    }
  }

  @override
  Future<List<PrayerModel>> searchPrayers(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final prayers = _box.values.where((prayer) {
        return prayer.title.toLowerCase().contains(lowerQuery) ||
            prayer.description.toLowerCase().contains(lowerQuery) ||
            (prayer.requesterName?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
      prayers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return prayers;
    } catch (e) {
      throw CacheException(message: 'Failed to search prayers: $e');
    }
  }
}
