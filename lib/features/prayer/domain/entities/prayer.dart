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

  /// Image URL for testimony (miracle photo, sunset, etc.)
  final String? testimonyImageUrl;

  /// Whether this testimony is shared publicly with the community
  final bool isPublicTestimony;

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
    this.testimonyImageUrl,
    this.isPublicTestimony = false,
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
    String? testimonyImageUrl,
    bool? isPublicTestimony,
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
      testimonyImageUrl: testimonyImageUrl ?? this.testimonyImageUrl,
      isPublicTestimony: isPublicTestimony ?? this.isPublicTestimony,
    );
  }

  /// Whether this prayer has been answered and has a testimony.
  bool get hasTestimony => status == PrayerStatus.answered && testimony != null && testimony!.isNotEmpty;

  /// Days since the prayer was answered.
  int? get daysSinceAnswered {
    if (answeredAt == null) return null;
    return DateTime.now().difference(answeredAt!).inDays;
  }

  /// Days the prayer was active before being answered.
  int? get daysToAnswer {
    if (answeredAt == null) return null;
    return answeredAt!.difference(createdAt).inDays;
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
        testimonyImageUrl,
        isPublicTestimony,
      ];
}
