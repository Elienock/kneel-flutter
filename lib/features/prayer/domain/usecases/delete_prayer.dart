import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:quick_church/core/error/failures.dart';
import 'package:quick_church/core/usecases/usecase.dart';
import 'package:quick_church/features/prayer/domain/repositories/i_prayer_repository.dart';

/// Parameters for deleting a prayer.
class DeletePrayerParams extends Equatable {
  final String id;

  const DeletePrayerParams({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Use case for deleting a prayer.
@lazySingleton
class DeletePrayer implements UseCase<({bool? data, Failure? failure}), DeletePrayerParams> {
  final IPrayerRepository _repository;

  DeletePrayer(this._repository);

  @override
  Future<({bool? data, Failure? failure})> call(DeletePrayerParams params) {
    return _repository.deletePrayer(params.id);
  }
}
