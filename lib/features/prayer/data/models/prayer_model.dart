import 'package:hive/hive.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';

part 'prayer_model.g.dart';

/// Hive type adapter for PrayerStatus enum.
@HiveType(typeId: 0)
enum PrayerStatusModel {
  @HiveField(0)
  active,
  @HiveField(1)
  answered,
  @HiveField(2)
  archived,
}

/// Hive type adapter for PrayerPriority enum.
@HiveType(typeId: 1)
enum PrayerPriorityModel {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
  @HiveField(3)
  urgent,
}

/// Data model for Prayer with Hive annotations for local persistence.
///
/// This model handles serialization/deserialization and mapping
/// to/from the domain entity.
@HiveType(typeId: 2)
class PrayerModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String? requesterName;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime? updatedAt;

  @HiveField(6)
  final DateTime? answeredAt;

  @HiveField(7)
  final PrayerStatusModel status;

  @HiveField(8)
  final PrayerPriorityModel priority;

  // Field 9 was isPrivate - kept for backward compatibility but no longer used
  @HiveField(9, defaultValue: false)
  final bool legacyIsPrivate;

  @HiveField(10)
  final int prayerCount;

  @HiveField(11)
  final List<String> tags;

  @HiveField(12)
  final String? testimony;

  @HiveField(13)
  final String? scriptureReference;

  @HiveField(14)
  final DateTime? lastPrayedAt;

  @HiveField(15, defaultValue: false)
  final bool isLocked;

  PrayerModel({
    required this.id,
    required this.title,
    required this.description,
    this.requesterName,
    required this.createdAt,
    this.updatedAt,
    this.answeredAt,
    this.lastPrayedAt,
    required this.status,
    required this.priority,
    this.legacyIsPrivate = false,
    this.isLocked = false,
    required this.prayerCount,
    required this.tags,
    this.testimony,
    this.scriptureReference,
  });

  /// Creates a PrayerModel from a domain Prayer entity.
  factory PrayerModel.fromEntity(Prayer prayer) {
    return PrayerModel(
      id: prayer.id,
      title: prayer.title,
      description: prayer.description,
      requesterName: prayer.requesterName,
      createdAt: prayer.createdAt,
      updatedAt: prayer.updatedAt,
      answeredAt: prayer.answeredAt,
      lastPrayedAt: prayer.lastPrayedAt,
      status: _mapStatusToModel(prayer.status),
      priority: _mapPriorityToModel(prayer.priority),
      legacyIsPrivate: false,
      isLocked: prayer.isLocked,
      prayerCount: prayer.prayerCount,
      tags: List<String>.from(prayer.tags),
      testimony: prayer.testimony,
      scriptureReference: prayer.scriptureReference,
    );
  }

  /// Converts this model to a domain Prayer entity.
  Prayer toEntity() {
    return Prayer(
      id: id,
      title: title,
      description: description,
      requesterName: requesterName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      answeredAt: answeredAt,
      lastPrayedAt: lastPrayedAt,
      status: _mapStatusToEntity(status),
      priority: _mapPriorityToEntity(priority),
      isLocked: isLocked,
      prayerCount: prayerCount,
      tags: List<String>.from(tags),
      testimony: testimony,
      scriptureReference: scriptureReference,
    );
  }

  /// Creates a copy of this model with updated fields.
  PrayerModel copyWith({
    String? id,
    String? title,
    String? description,
    String? requesterName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? answeredAt,
    DateTime? lastPrayedAt,
    PrayerStatusModel? status,
    PrayerPriorityModel? priority,
    bool? isLocked,
    int? prayerCount,
    List<String>? tags,
    String? testimony,
    String? scriptureReference,
  }) {
    return PrayerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requesterName: requesterName ?? this.requesterName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      lastPrayedAt: lastPrayedAt ?? this.lastPrayedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      legacyIsPrivate: false,
      isLocked: isLocked ?? this.isLocked,
      prayerCount: prayerCount ?? this.prayerCount,
      tags: tags ?? this.tags,
      testimony: testimony ?? this.testimony,
      scriptureReference: scriptureReference ?? this.scriptureReference,
    );
  }

  static PrayerStatusModel _mapStatusToModel(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.active:
        return PrayerStatusModel.active;
      case PrayerStatus.answered:
        return PrayerStatusModel.answered;
      case PrayerStatus.archived:
        return PrayerStatusModel.archived;
    }
  }

  static PrayerStatus _mapStatusToEntity(PrayerStatusModel status) {
    switch (status) {
      case PrayerStatusModel.active:
        return PrayerStatus.active;
      case PrayerStatusModel.answered:
        return PrayerStatus.answered;
      case PrayerStatusModel.archived:
        return PrayerStatus.archived;
    }
  }

  static PrayerPriorityModel _mapPriorityToModel(PrayerPriority priority) {
    switch (priority) {
      case PrayerPriority.low:
        return PrayerPriorityModel.low;
      case PrayerPriority.medium:
        return PrayerPriorityModel.medium;
      case PrayerPriority.high:
        return PrayerPriorityModel.high;
      case PrayerPriority.urgent:
        return PrayerPriorityModel.urgent;
    }
  }

  static PrayerPriority _mapPriorityToEntity(PrayerPriorityModel priority) {
    switch (priority) {
      case PrayerPriorityModel.low:
        return PrayerPriority.low;
      case PrayerPriorityModel.medium:
        return PrayerPriority.medium;
      case PrayerPriorityModel.high:
        return PrayerPriority.high;
      case PrayerPriorityModel.urgent:
        return PrayerPriority.urgent;
    }
  }
}
