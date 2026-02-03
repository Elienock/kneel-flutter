import 'package:equatable/equatable.dart';

/// Focus areas for Sacred Time sessions.
enum SacredFocusArea {
  prayer('Prayer', 'Intimate conversation with God'),
  bibleStudy('Bible Study', 'Deep dive into Scripture'),
  meditation('Meditation', 'Silent reflection and contemplation'),
  sermonPrep('Sermon Prep', 'Preparing to share God\'s word');

  final String label;
  final String description;
  const SacredFocusArea(this.label, this.description);
}

/// Ambient sound options for the sanctuary.
enum SacredAmbience {
  silence('Silence', null),
  gentleRain('Gentle Rain', 'rain'),
  softInstrumental('Soft Instrumental', 'instrumental');

  final String label;
  final String? assetKey;
  const SacredAmbience(this.label, this.assetKey);
}

/// Duration presets for Sacred Time sessions.
/// Use `unlimited` for stopwatch mode (counts UP instead of DOWN).
enum SacredDuration {
  five(5, '5 min'),
  fifteen(15, '15 min'),
  thirty(30, '30 min'),
  sixty(60, '1 hour'),
  unlimited(0, 'No Limit'); // Stopwatch mode - timer counts UP

  final int minutes;
  final String label;
  const SacredDuration(this.minutes, this.label);

  /// Whether this is stopwatch mode (no time limit).
  bool get isStopwatch => this == SacredDuration.unlimited;
}

/// Configuration for a Sacred Time session.
class SacredTimeConfig extends Equatable {
  final SacredFocusArea focusArea;
  final SacredDuration duration;
  final SacredAmbience ambience;

  /// Optional prayer ID when focusing on a specific prayer request.
  /// This enables persistence tracking ("Prayed X times" badge).
  final String? prayerId;

  /// Optional prayer title for display during the session.
  final String? prayerTitle;

  const SacredTimeConfig({
    this.focusArea = SacredFocusArea.prayer,
    this.duration = SacredDuration.fifteen,
    this.ambience = SacredAmbience.silence,
    this.prayerId,
    this.prayerTitle,
  });

  SacredTimeConfig copyWith({
    SacredFocusArea? focusArea,
    SacredDuration? duration,
    SacredAmbience? ambience,
    String? prayerId,
    String? prayerTitle,
  }) {
    return SacredTimeConfig(
      focusArea: focusArea ?? this.focusArea,
      duration: duration ?? this.duration,
      ambience: ambience ?? this.ambience,
      prayerId: prayerId ?? this.prayerId,
      prayerTitle: prayerTitle ?? this.prayerTitle,
    );
  }

  @override
  List<Object?> get props => [focusArea, duration, ambience, prayerId, prayerTitle];
}

/// A completed Sacred Time session record.
class SacredTimeSession extends Equatable {
  final String id;
  final String? userId;
  final SacredFocusArea focusArea;
  final int durationMinutes;
  final int actualDurationSeconds;
  final String content;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool wasCompleted;

  const SacredTimeSession({
    required this.id,
    this.userId,
    required this.focusArea,
    required this.durationMinutes,
    required this.actualDurationSeconds,
    required this.content,
    required this.startedAt,
    this.completedAt,
    this.wasCompleted = false,
  });

  /// Creates a session from JSON (for local storage).
  factory SacredTimeSession.fromJson(Map<String, dynamic> json) {
    return SacredTimeSession(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      focusArea: SacredFocusArea.values.firstWhere(
        (e) => e.name == json['focus_area'],
        orElse: () => SacredFocusArea.prayer,
      ),
      durationMinutes: json['duration_minutes'] as int,
      actualDurationSeconds: json['actual_duration_seconds'] as int,
      content: json['content'] as String? ?? '',
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      wasCompleted: json['was_completed'] as bool? ?? false,
    );
  }

  /// Converts session to JSON for local storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'focus_area': focusArea.name,
      'duration_minutes': durationMinutes,
      'actual_duration_seconds': actualDurationSeconds,
      'content': content,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'was_completed': wasCompleted,
    };
  }

  SacredTimeSession copyWith({
    String? id,
    String? userId,
    SacredFocusArea? focusArea,
    int? durationMinutes,
    int? actualDurationSeconds,
    String? content,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? wasCompleted,
  }) {
    return SacredTimeSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      focusArea: focusArea ?? this.focusArea,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      actualDurationSeconds: actualDurationSeconds ?? this.actualDurationSeconds,
      content: content ?? this.content,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      wasCompleted: wasCompleted ?? this.wasCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        focusArea,
        durationMinutes,
        actualDurationSeconds,
        content,
        startedAt,
        completedAt,
        wasCompleted,
      ];
}
