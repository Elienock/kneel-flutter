import 'package:hive/hive.dart';

part 'prayer_session_model.g.dart';

/// Hive model for tracking individual prayer focus sessions.
@HiveType(typeId: 3)
class PrayerSessionModel extends HiveObject {
  /// Unique session ID.
  @HiveField(0)
  final String id;

  /// Date of the session (normalized to midnight for grouping by day).
  @HiveField(1)
  final DateTime date;

  /// Duration of the session in seconds.
  @HiveField(2)
  final int durationSeconds;

  /// Timestamp when the session started.
  @HiveField(3)
  final DateTime startedAt;

  /// Timestamp when the session ended.
  @HiveField(4)
  final DateTime endedAt;

  /// Whether this was a deep prayer session (10+ minutes).
  @HiveField(5)
  final bool isDeepSession;

  /// Number of prayers prayed during this session.
  @HiveField(6)
  final int prayersPrayed;

  /// Optional notes about the session.
  @HiveField(7)
  final String? notes;

  PrayerSessionModel({
    required this.id,
    required this.date,
    required this.durationSeconds,
    required this.startedAt,
    required this.endedAt,
    required this.isDeepSession,
    required this.prayersPrayed,
    this.notes,
  });

  /// Creates a copy with updated fields.
  PrayerSessionModel copyWith({
    String? id,
    DateTime? date,
    int? durationSeconds,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isDeepSession,
    int? prayersPrayed,
    String? notes,
  }) {
    return PrayerSessionModel(
      id: id ?? this.id,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isDeepSession: isDeepSession ?? this.isDeepSession,
      prayersPrayed: prayersPrayed ?? this.prayersPrayed,
      notes: notes ?? this.notes,
    );
  }
}

/// Helper to normalize a DateTime to midnight (for day grouping).
DateTime normalizeDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}
