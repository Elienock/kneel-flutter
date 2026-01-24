import 'package:injectable/injectable.dart';
import 'package:quick_church/core/error/exceptions.dart';
import 'package:quick_church/core/error/failures.dart';
import 'package:quick_church/features/prayer/data/datasources/prayer_local_data_source.dart';
import 'package:quick_church/features/prayer/data/models/prayer_model.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/domain/repositories/i_prayer_repository.dart';

/// Implementation of [IPrayerRepository] that uses local data source.
@LazySingleton(as: IPrayerRepository)
class PrayerRepositoryImpl implements IPrayerRepository {
  final PrayerLocalDataSource _localDataSource;

  PrayerRepositoryImpl(this._localDataSource);

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
}
