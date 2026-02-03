import 'package:equatable/equatable.dart';

/// A single prayer session record.
/// Tracks when and how long a user prayed for a specific prayer request.
/// This enables the "Persistence" tracking - showing "Prayed 12x" badges
/// and feeding the Insights heatmap/streaks even for manual entries.
class PrayerSession extends Equatable {
  /// Unique identifier for this session
  final String id;

  /// The prayer request this session is for
  final String prayerId;

  /// User who prayed (for multi-user sync)
  final String? userId;

  /// Duration of the prayer session in minutes
  final int durationMinutes;

  /// Actual duration in seconds (for Sacred Time sessions)
  final int? actualDurationSeconds;

  /// When this prayer session occurred
  final DateTime prayedAt;

  /// Whether this was manually logged (vs. tracked via Sacred Time)
  final bool isManual;

  /// Optional notes about this specific session
  final String? notes;

  /// When this record was created in the system
  final DateTime createdAt;

  /// Whether this session has been synced to Supabase
  final bool isSynced;

  const PrayerSession({
    required this.id,
    required this.prayerId,
    this.userId,
    required this.durationMinutes,
    this.actualDurationSeconds,
    required this.prayedAt,
    this.isManual = false,
    this.notes,
    required this.createdAt,
    this.isSynced = false,
  });

  PrayerSession copyWith({
    String? id,
    String? prayerId,
    String? userId,
    int? durationMinutes,
    int? actualDurationSeconds,
    DateTime? prayedAt,
    bool? isManual,
    String? notes,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return PrayerSession(
      id: id ?? this.id,
      prayerId: prayerId ?? this.prayerId,
      userId: userId ?? this.userId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      actualDurationSeconds: actualDurationSeconds ?? this.actualDurationSeconds,
      prayedAt: prayedAt ?? this.prayedAt,
      isManual: isManual ?? this.isManual,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Creates a session from JSON (for Supabase/local storage).
  factory PrayerSession.fromJson(Map<String, dynamic> json) {
    return PrayerSession(
      id: json['id'] as String,
      prayerId: json['prayer_id'] as String,
      userId: json['user_id'] as String?,
      durationMinutes: json['duration_minutes'] as int,
      actualDurationSeconds: json['actual_duration_seconds'] as int?,
      prayedAt: DateTime.parse(json['prayed_at'] as String),
      isManual: json['is_manual'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isSynced: json['is_synced'] as bool? ?? true,
    );
  }

  /// Converts session to JSON for storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prayer_id': prayerId,
      'user_id': userId,
      'duration_minutes': durationMinutes,
      'actual_duration_seconds': actualDurationSeconds,
      'prayed_at': prayedAt.toIso8601String(),
      'is_manual': isManual,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced,
    };
  }

  /// Formats the duration for display.
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (mins == 0) {
      return '$hours hr';
    }
    return '$hours hr $mins min';
  }

  @override
  List<Object?> get props => [
        id,
        prayerId,
        userId,
        durationMinutes,
        actualDurationSeconds,
        prayedAt,
        isManual,
        notes,
        createdAt,
        isSynced,
      ];
}
