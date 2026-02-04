import 'package:equatable/equatable.dart';

/// Types of sessions that can be tracked.
/// Unified across Prayer Sanctuary and Focus modes.
enum SessionType {
  prayer('Prayer'),
  bibleStudy('Bible Study'),
  meditation('Meditation'),
  sermonPrep('Sermon Prep'),
  worship('Worship'),
  journaling('Journaling'),
  specificPrayer('Focused Prayer');

  final String label;
  const SessionType(this.label);

  /// Convert from Sacred Time focus area name.
  static SessionType fromFocusName(String name) {
    switch (name) {
      case 'prayer':
        return SessionType.prayer;
      case 'bibleStudy':
      case 'bible_study':
        return SessionType.bibleStudy;
      case 'meditation':
        return SessionType.meditation;
      case 'sermonPrep':
      case 'sermon_prep':
        return SessionType.sermonPrep;
      case 'worship':
        return SessionType.worship;
      case 'journaling':
        return SessionType.journaling;
      case 'specificPrayer':
      case 'specific_prayer':
      case 'generalPrayer':
      case 'general_prayer':
        return SessionType.prayer;
      default:
        return SessionType.prayer;
    }
  }

  /// Convert from Focus feature FocusType.
  static SessionType fromFocusType(String dbValue) {
    switch (dbValue) {
      case 'bible_study':
        return SessionType.bibleStudy;
      case 'meditation':
        return SessionType.meditation;
      case 'general_prayer':
        return SessionType.prayer;
      case 'specific_prayer':
        return SessionType.specificPrayer;
      case 'worship':
        return SessionType.worship;
      case 'journaling':
        return SessionType.journaling;
      default:
        return SessionType.prayer;
    }
  }
}

/// Represents a user session for insights tracking.
/// Maps to the 'user_sessions' table in Supabase.
class UserSession extends Equatable {
  final String id;
  final String userId;
  final SessionType type;
  final int durationMinutes;
  final int actualDurationSeconds;
  final DateTime sessionDate;
  final bool completed;
  final bool prayerAnswered;
  final String? noteId; // Link to sermon note if saved
  final DateTime createdAt;

  const UserSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.durationMinutes,
    required this.actualDurationSeconds,
    required this.sessionDate,
    this.completed = true,
    this.prayerAnswered = false,
    this.noteId,
    required this.createdAt,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: SessionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SessionType.prayer,
      ),
      durationMinutes: json['duration_minutes'] as int,
      actualDurationSeconds: json['actual_duration_seconds'] as int? ?? 0,
      sessionDate: DateTime.parse(json['session_date'] as String),
      completed: json['completed'] as bool? ?? true,
      prayerAnswered: json['prayer_answered'] as bool? ?? false,
      noteId: json['note_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'duration_minutes': durationMinutes,
      'actual_duration_seconds': actualDurationSeconds,
      'session_date': sessionDate.toUtc().toIso8601String().split('T')[0],
      'completed': completed,
      'prayer_answered': prayerAnswered,
      'note_id': noteId,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'type': type.name,
      'duration_minutes': durationMinutes,
      'actual_duration_seconds': actualDurationSeconds,
      'session_date': sessionDate.toUtc().toIso8601String().split('T')[0],
      'completed': completed,
      'prayer_answered': prayerAnswered,
      'note_id': noteId,
    };
  }

  UserSession copyWith({
    String? id,
    String? userId,
    SessionType? type,
    int? durationMinutes,
    int? actualDurationSeconds,
    DateTime? sessionDate,
    bool? completed,
    bool? prayerAnswered,
    String? noteId,
    DateTime? createdAt,
  }) {
    return UserSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      actualDurationSeconds: actualDurationSeconds ?? this.actualDurationSeconds,
      sessionDate: sessionDate ?? this.sessionDate,
      completed: completed ?? this.completed,
      prayerAnswered: prayerAnswered ?? this.prayerAnswered,
      noteId: noteId ?? this.noteId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        durationMinutes,
        actualDurationSeconds,
        sessionDate,
        completed,
        prayerAnswered,
        noteId,
        createdAt,
      ];
}

/// Daily activity data for the GitHub-style heatmap.
class DailyActivity extends Equatable {
  final DateTime date;
  final int sessionCount;
  final int totalMinutes;
  final List<SessionType> types;

  const DailyActivity({
    required this.date,
    required this.sessionCount,
    required this.totalMinutes,
    required this.types,
  });

  /// Activity level from 0-4 for heatmap coloring.
  int get activityLevel {
    if (sessionCount == 0) return 0;
    if (totalMinutes < 15) return 1;
    if (totalMinutes < 30) return 2;
    if (totalMinutes < 60) return 3;
    return 4;
  }

  @override
  List<Object?> get props => [date, sessionCount, totalMinutes, types];
}

/// User streak statistics.
class StreakStats extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final int totalSessions;
  final int totalMinutes;
  final int answeredPrayers;
  final DateTime? lastSessionDate;

  const StreakStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.answeredPrayers = 0,
    this.lastSessionDate,
  });

  /// Whether the user has an active streak today.
  bool get isStreakActive {
    if (lastSessionDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      lastSessionDate!.year,
      lastSessionDate!.month,
      lastSessionDate!.day,
    );
    return today.difference(lastDay).inDays <= 1;
  }

  /// Motivational message based on streak.
  String get motivationalMessage {
    if (currentStreak == 0) {
      return "Start your journey today!";
    } else if (currentStreak == 1) {
      return "Day 1! Every journey begins with a single step.";
    } else if (currentStreak < 7) {
      return "Day $currentStreak! Building momentum for the Lord.";
    } else if (currentStreak < 14) {
      return "Day $currentStreak! A week strong in faith!";
    } else if (currentStreak < 30) {
      return "Day $currentStreak! You are on fire for the Lord!";
    } else if (currentStreak < 100) {
      return "Day $currentStreak! A faithful servant of God!";
    } else {
      return "Day $currentStreak! Legendary devotion!";
    }
  }

  @override
  List<Object?> get props => [
        currentStreak,
        longestStreak,
        totalSessions,
        totalMinutes,
        answeredPrayers,
        lastSessionDate,
      ];
}
