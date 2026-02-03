import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:quick_church/core/error/exceptions.dart';
import 'package:quick_church/core/error/failures.dart';
import 'package:quick_church/features/prayer/data/datasources/prayer_local_data_source.dart';
import 'package:quick_church/features/prayer/data/models/prayer_log_model.dart';
import 'package:quick_church/features/prayer/data/models/prayer_model.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer_session.dart';
import 'package:quick_church/features/prayer/domain/repositories/i_prayer_repository.dart';

/// Implementation of [IPrayerRepository] that uses local data source.
@LazySingleton(as: IPrayerRepository)
class PrayerRepositoryImpl implements IPrayerRepository {
  final PrayerLocalDataSource _localDataSource;
  static const String _prayerLogsBoxName = 'prayer_logs';

  PrayerRepositoryImpl(this._localDataSource);

  /// Gets or opens the prayer logs Hive box.
  Future<Box<PrayerLogModel>> _getPrayerLogsBox() async {
    if (Hive.isBoxOpen(_prayerLogsBoxName)) {
      return Hive.box<PrayerLogModel>(_prayerLogsBoxName);
    }
    return await Hive.openBox<PrayerLogModel>(_prayerLogsBoxName);
  }

  @override
  Future<({List<Prayer>? data, Failure? failure})> getAllPrayers() async {
    try {
      final models = await _localDataSource.getAllPrayers();
      final prayers = models.map((m) => m.toEntity()).toList();
      return (data: prayers, failure: null);
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({List<Prayer>? data, Failure? failure})> getPrayersByStatus(
    PrayerStatus status,
  ) async {
    try {
      final statusModel = _mapStatusToModel(status);
      final models = await _localDataSource.getPrayersByStatus(statusModel);
      final prayers = models.map((m) => m.toEntity()).toList();
      return (data: prayers, failure: null);
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({Prayer? data, Failure? failure})> getPrayerById(String id) async {
    try {
      final model = await _localDataSource.getPrayerById(id);
      return (data: model.toEntity(), failure: null);
    } on NotFoundException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({Prayer? data, Failure? failure})> createPrayer(Prayer prayer) async {
    try {
      final model = PrayerModel.fromEntity(prayer);
      final created = await _localDataSource.createPrayer(model);
      return (data: created.toEntity(), failure: null);
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({Prayer? data, Failure? failure})> updatePrayer(Prayer prayer) async {
    try {
      final model = PrayerModel.fromEntity(prayer);
      final updated = await _localDataSource.updatePrayer(model);
      return (data: updated.toEntity(), failure: null);
    } on NotFoundException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({bool? data, Failure? failure})> deletePrayer(String id) async {
    try {
      final result = await _localDataSource.deletePrayer(id);
      return (data: result, failure: null);
    } on NotFoundException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({Prayer? data, Failure? failure})> incrementPrayerCount(
    String id,
  ) async {
    try {
      final model = await _localDataSource.getPrayerById(id);
      final updated = model.copyWith(
        prayerCount: model.prayerCount + 1,
        updatedAt: DateTime.now(),
      );
      final result = await _localDataSource.updatePrayer(updated);
      return (data: result.toEntity(), failure: null);
    } on NotFoundException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({Prayer? data, Failure? failure})> markAsAnswered(String id) async {
    try {
      final model = await _localDataSource.getPrayerById(id);
      final updated = model.copyWith(
        status: PrayerStatusModel.answered,
        answeredAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final result = await _localDataSource.updatePrayer(updated);
      return (data: result.toEntity(), failure: null);
    } on NotFoundException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({Prayer? data, Failure? failure})> markAsActive(String id) async {
    try {
      final model = await _localDataSource.getPrayerById(id);
      final updated = model.copyWith(
        status: PrayerStatusModel.active,
        updatedAt: DateTime.now(),
      );
      final result = await _localDataSource.updatePrayer(updated);
      return (data: result.toEntity(), failure: null);
    } on NotFoundException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({Prayer? data, Failure? failure})> updateTestimony(
    String id,
    String testimony,
  ) async {
    try {
      final model = await _localDataSource.getPrayerById(id);
      final updated = model.copyWith(
        testimony: testimony,
        updatedAt: DateTime.now(),
      );
      final result = await _localDataSource.updatePrayer(updated);
      return (data: result.toEntity(), failure: null);
    } on NotFoundException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({List<Prayer>? data, Failure? failure})> searchPrayers(
    String query,
  ) async {
    try {
      final models = await _localDataSource.searchPrayers(query);
      final prayers = models.map((m) => m.toEntity()).toList();
      return (data: prayers, failure: null);
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  @override
  Future<({Prayer? data, Failure? failure})> toggleLock(String id) async {
    try {
      final model = await _localDataSource.getPrayerById(id);
      final updated = model.copyWith(
        isLocked: !model.isLocked,
        updatedAt: DateTime.now(),
      );
      final result = await _localDataSource.updatePrayer(updated);
      return (data: result.toEntity(), failure: null);
    } on NotFoundException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    }
  }

  PrayerStatusModel _mapStatusToModel(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.active:
        return PrayerStatusModel.active;
      case PrayerStatus.answered:
        return PrayerStatusModel.answered;
      case PrayerStatus.archived:
        return PrayerStatusModel.archived;
    }
  }

  // ============================================================================
  // PRAYER PERSISTENCE / SESSION LOGGING
  // ============================================================================

  @override
  Future<({Prayer? data, Failure? failure})> recordPrayerSession({
    required String prayerId,
    required int durationMinutes,
    int? actualDurationSeconds,
    DateTime? prayedAt,
    bool isManual = false,
    String? notes,
  }) async {
    try {
      // Get the prayer first
      final prayerModel = await _localDataSource.getPrayerById(prayerId);

      // Create the log entry
      final now = DateTime.now();
      final logModel = PrayerLogModel(
        id: const Uuid().v4(),
        prayerId: prayerId,
        userId: null, // Will be set by Supabase sync
        durationMinutes: durationMinutes,
        actualDurationSeconds: actualDurationSeconds,
        prayedAt: prayedAt ?? now,
        isManual: isManual,
        notes: notes,
        createdAt: now,
        isSynced: false,
      );

      // Save the log
      final box = await _getPrayerLogsBox();
      await box.put(logModel.id, logModel);

      // Update the prayer's count and lastPrayedAt
      final updatedPrayer = prayerModel.copyWith(
        prayerCount: prayerModel.prayerCount + 1,
        lastPrayedAt: prayedAt ?? now,
        updatedAt: now,
      );
      final result = await _localDataSource.updatePrayer(updatedPrayer);

      return (data: result.toEntity(), failure: null);
    } on NotFoundException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    } on CacheException catch (e) {
      return (data: null, failure: CacheFailure(message: e.message));
    } catch (e) {
      return (data: null, failure: CacheFailure(message: 'Failed to record prayer session: $e'));
    }
  }

  @override
  Future<({List<PrayerSession>? data, Failure? failure})> getPrayerHistory(
    String prayerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final box = await _getPrayerLogsBox();
      final allLogs = box.values
          .where((log) => log.prayerId == prayerId)
          .toList()
        ..sort((a, b) => b.prayedAt.compareTo(a.prayedAt));

      final paginatedLogs = allLogs.skip(offset).take(limit).toList();
      final sessions = paginatedLogs.map((log) => log.toEntity()).toList();

      return (data: sessions, failure: null);
    } catch (e) {
      return (data: null, failure: CacheFailure(message: 'Failed to get prayer history: $e'));
    }
  }

  @override
  Future<({Map<String, dynamic>? data, Failure? failure})> getPrayerPersistenceStats(
    String prayerId,
  ) async {
    try {
      final box = await _getPrayerLogsBox();
      final logs = box.values.where((log) => log.prayerId == prayerId).toList();

      if (logs.isEmpty) {
        return (
          data: {
            'total_sessions': 0,
            'total_minutes': 0,
            'manual_sessions': 0,
            'timed_sessions': 0,
            'first_prayed': null,
            'last_prayed': null,
            'longest_session_minutes': 0,
            'days_praying': 0,
          },
          failure: null,
        );
      }

      final totalSessions = logs.length;
      final totalMinutes = logs.fold<int>(0, (sum, log) => sum + log.durationMinutes);
      final manualSessions = logs.where((log) => log.isManual).length;
      final timedSessions = totalSessions - manualSessions;

      logs.sort((a, b) => a.prayedAt.compareTo(b.prayedAt));
      final firstPrayed = logs.first.prayedAt;
      final lastPrayed = logs.last.prayedAt;
      final longestSession = logs.fold<int>(0, (max, log) {
        return log.durationMinutes > max ? log.durationMinutes : max;
      });
      final daysPraying = lastPrayed.difference(firstPrayed).inDays + 1;

      return (
        data: {
          'total_sessions': totalSessions,
          'total_minutes': totalMinutes,
          'manual_sessions': manualSessions,
          'timed_sessions': timedSessions,
          'first_prayed': firstPrayed.toIso8601String(),
          'last_prayed': lastPrayed.toIso8601String(),
          'longest_session_minutes': longestSession,
          'days_praying': daysPraying,
        },
        failure: null,
      );
    } catch (e) {
      return (data: null, failure: CacheFailure(message: 'Failed to get persistence stats: $e'));
    }
  }
}
