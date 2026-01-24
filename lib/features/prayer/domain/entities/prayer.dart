import 'package:equatable/equatable.dart';

/// Represents the status of a prayer request.
enum PrayerStatus {
  active,
  answered,
  archived,
}

/// Represents the priority level of a prayer request.
enum PrayerPriority {
  low,
  medium,
  high,
  urgent,
}

/// Prayer entity representing a prayer request in the domain layer.
///
/// This is a pure domain object with no framework dependencies.
class Prayer extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? requesterName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? answeredAt;
  final DateTime? lastPrayedAt;
  final PrayerStatus status;
  final PrayerPriority priority;
  final bool isLocked;
  final int prayerCount;
  final List<String> tags;
  final String? testimony;
  final String? scriptureReference;

  const Prayer({
    required this.id,
    required this.title,
    required this.description,
    this.requesterName,
    required this.createdAt,
    this.updatedAt,
    this.answeredAt,
    this.lastPrayedAt,
    this.status = PrayerStatus.active,
    this.priority = PrayerPriority.medium,
    this.isLocked = false,
    this.prayerCount = 0,
    this.tags = const [],
    this.testimony,
    this.scriptureReference,
  });

  /// Creates a copy of this Prayer with the given fields replaced.
  Prayer copyWith({
    String? id,
    String? title,
    String? description,
    String? requesterName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? answeredAt,
    DateTime? lastPrayedAt,
    PrayerStatus? status,
    PrayerPriority? priority,
    bool? isLocked,
    int? prayerCount,
    List<String>? tags,
    String? testimony,
    String? scriptureReference,
  }) {
    return Prayer(
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
      isLocked: isLocked ?? this.isLocked,
      prayerCount: prayerCount ?? this.prayerCount,
      tags: tags ?? this.tags,
      testimony: testimony ?? this.testimony,
      scriptureReference: scriptureReference ?? this.scriptureReference,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        requesterName,
        createdAt,
        updatedAt,
        answeredAt,
        lastPrayedAt,
        status,
        priority,
        isLocked,
        prayerCount,
        tags,
        testimony,
        scriptureReference,
      ];
}
