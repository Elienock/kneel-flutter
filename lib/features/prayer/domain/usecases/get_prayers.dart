import 'package:injectable/injectable.dart';
import 'package:quick_church/core/error/failures.dart';
import 'package:quick_church/core/usecases/usecase.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/domain/repositories/i_prayer_repository.dart';

/// Use case for retrieving all prayers.
@lazySingleton
class GetPrayers implements UseCase<({List<Prayer>? data, Failure? failure}), NoParams> {
  final IPrayerRepository _repository;

  GetPrayers(this._repository);

  @override
  Future<({List<Prayer>? data, Failure? failure})> call(NoParams params) {
    return _repository.getAllPrayers();
  }
}
