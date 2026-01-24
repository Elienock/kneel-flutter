import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:quick_church/core/error/failures.dart';
import 'package:quick_church/core/usecases/usecase.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/domain/repositories/i_prayer_repository.dart';
import 'package:uuid/uuid.dart';

/// Parameters for creating a new prayer.
class AddPrayerParams extends Equatable {
  final String title;
  final String description;
  final String? requesterName;
  final PrayerPriority priority;
  final bool isLocked;
  final List<String> tags;

  const AddPrayerParams({
    required this.title,
    required this.description,
    this.requesterName,
    this.priority = PrayerPriority.medium,
    this.isLocked = false,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [
        title,
        description,
        requesterName,
        priority,
        isLocked,
        tags,
      ];
}

/// Use case for adding a new prayer.
@lazySingleton
class AddPrayer implements UseCase<({Prayer? data, Failure? failure}), AddPrayerParams> {
  final IPrayerRepository _repository;
  final Uuid _uuid;

  AddPrayer(this._repository, this._uuid);

  @override
  Future<({Prayer? data, Failure? failure})> call(AddPrayerParams params) {
    final prayer = Prayer(
      id: _uuid.v4(),
      title: params.title,
      description: params.description,
      requesterName: params.requesterName,
      createdAt: DateTime.now(),
      priority: params.priority,
      isLocked: params.isLocked,
      tags: params.tags,
    );

    return _repository.createPrayer(prayer);
  }
}
