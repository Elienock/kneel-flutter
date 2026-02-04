import 'package:equatable/equatable.dart';

/// A scripture reference with optional text.
class ScriptureReference extends Equatable {
  final String reference; // e.g., "John 3:16"
  final String? text; // The actual verse text (optional)

  const ScriptureReference({
    required this.reference,
    this.text,
  });

  factory ScriptureReference.fromJson(Map<String, dynamic> json) {
    return ScriptureReference(
      reference: json['reference'] as String? ?? '',
      text: json['text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      if (text != null) 'text': text,
    };
  }

  @override
  List<Object?> get props => [reference, text];
}

/// A single prayer point within a pulpit prayer group.
class PulpitPrayerPoint extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final String? description;
  final List<ScriptureReference> scriptures;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PulpitPrayerPoint({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    this.scriptures = const [],
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PulpitPrayerPoint.fromJson(Map<String, dynamic> json) {
    final scripturesJson = json['scriptures'];
    List<ScriptureReference> scriptures = [];

    if (scripturesJson != null) {
      if (scripturesJson is List) {
        scriptures = scripturesJson
            .map((s) => ScriptureReference.fromJson(s as Map<String, dynamic>))
            .toList();
      }
    }

    return PulpitPrayerPoint(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scriptures: scriptures,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'description': description,
      'scriptures': scriptures.map((s) => s.toJson()).toList(),
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// For inserting new points (without id, created_at, updated_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'group_id': groupId,
      'title': title,
      'description': description,
      'scriptures': scriptures.map((s) => s.toJson()).toList(),
      'sort_order': sortOrder,
    };
  }

  PulpitPrayerPoint copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    List<ScriptureReference>? scriptures,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PulpitPrayerPoint(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      scriptures: scriptures ?? this.scriptures,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        title,
        description,
        scriptures,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}

/// A group of prayer points for a pulpit session.
class PulpitPrayerGroup extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool autoAdvance;
  final int secondsPerPoint; // Timer duration in seconds
  final int timesUsed;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Prayer points in this group (loaded separately)
  final List<PulpitPrayerPoint> points;

  const PulpitPrayerGroup({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.autoAdvance = false,
    this.secondsPerPoint = 300, // 5 minutes default
    this.timesUsed = 0,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
    this.points = const [],
  });

  /// Duration as a Duration object.
  Duration get durationPerPoint => Duration(seconds: secondsPerPoint);

  /// Human-readable duration string.
  String get durationLabel {
    final minutes = secondsPerPoint ~/ 60;
    if (minutes == 1) return '1 minute';
    return '$minutes minutes';
  }

  factory PulpitPrayerGroup.fromJson(Map<String, dynamic> json) {
    return PulpitPrayerGroup(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      autoAdvance: json['auto_advance'] as bool? ?? false,
      secondsPerPoint: json['seconds_per_point'] as int? ?? 300,
      timesUsed: json['times_used'] as int? ?? 0,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      points: [], // Points loaded separately
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'auto_advance': autoAdvance,
      'seconds_per_point': secondsPerPoint,
      'times_used': timesUsed,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// For inserting new groups (without id, created_at, updated_at, times_used)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'auto_advance': autoAdvance,
      'seconds_per_point': secondsPerPoint,
    };
  }

  PulpitPrayerGroup copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? autoAdvance,
    int? secondsPerPoint,
    int? timesUsed,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PulpitPrayerPoint>? points,
  }) {
    return PulpitPrayerGroup(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      secondsPerPoint: secondsPerPoint ?? this.secondsPerPoint,
      timesUsed: timesUsed ?? this.timesUsed,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        autoAdvance,
        secondsPerPoint,
        timesUsed,
        lastUsedAt,
        createdAt,
        updatedAt,
        points,
      ];
}

/// Preset timer durations for pulpit mode.
enum PulpitTimerPreset {
  twoMinutes(120, '2 min'),
  threeMinutes(180, '3 min'),
  fiveMinutes(300, '5 min'),
  tenMinutes(600, '10 min'),
  fifteenMinutes(900, '15 min'),
  manual(0, 'Manual');

  final int seconds;
  final String label;

  const PulpitTimerPreset(this.seconds, this.label);

  bool get isManual => this == PulpitTimerPreset.manual;
}
