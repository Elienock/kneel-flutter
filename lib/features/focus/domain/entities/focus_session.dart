import 'package:equatable/equatable.dart';

/// Types of focus activities available.
enum FocusType {
  bibleStudy,
  meditation,
  generalPrayer,
  specificPrayer,
  worship,
  journaling,
}

/// Achievement milestones earned during focus sessions.
/// Achievements are calculated silently during focus and shown AFTER completion.
enum FocusAchievement {
  firstSession('First Steps', 'Completed your first focus session', 0, 'first_session'),
  fiveMinutes('Getting Started', 'Focused for 5 minutes', 5, 'five_minutes'),
  tenMinutes('Building Momentum', 'Focused for 10 minutes', 10, 'ten_minutes'),
  twentyMinutes('Deep Focus', 'Focused for 20 minutes', 20, 'twenty_minutes'),
  thirtyMinutes('Dedicated Time', 'Focused for 30 minutes', 30, 'thirty_minutes'),
  fortyFiveMinutes('Extended Session', 'Focused for 45 minutes', 45, 'forty_five_minutes'),
  oneHour('Hour of Power', 'Focused for a full hour', 60, 'one_hour'),
  ninetyMinutes('Marathon Session', 'Focused for 90 minutes', 90, 'ninety_minutes');

  final String title;
  final String description;
  final int minutesRequired;
  final String dbKey; // Database key for storage

  const FocusAchievement(this.title, this.description, this.minutesRequired, this.dbKey);

  /// Get all achievements earned for a given duration in minutes.
  static List<FocusAchievement> getAchievementsFor(int minutes) {
    return FocusAchievement.values
        .where((a) => a.minutesRequired > 0 && minutes >= a.minutesRequired)
        .toList();
  }

  /// Get the highest achievement for a duration.
  static FocusAchievement? getHighestFor(int minutes) {
    final achievements = getAchievementsFor(minutes);
    return achievements.isEmpty ? null : achievements.last;
  }

  /// Get next achievement to unlock.
  static FocusAchievement? getNextFor(int minutes) {
    for (final achievement in FocusAchievement.values) {
      if (achievement.minutesRequired > minutes) {
        return achievement;
      }
    }
    return null;
  }

  /// Parse from database key.
  static FocusAchievement? fromDbKey(String key) {
    for (final achievement in FocusAchievement.values) {
      if (achievement.dbKey == key) return achievement;
    }
    return null;
  }
}

extension FocusTypeExtension on FocusType {
  String get displayName {
    switch (this) {
      case FocusType.bibleStudy:
        return 'Bible Study';
      case FocusType.meditation:
        return 'Meditation';
      case FocusType.generalPrayer:
        return 'Prayer';
      case FocusType.specificPrayer:
        return 'Pray for Request';
      case FocusType.worship:
        return 'Worship';
      case FocusType.journaling:
        return 'Journaling';
    }
  }

  String get description {
    switch (this) {
      case FocusType.bibleStudy:
        return 'Read and study Scripture';
      case FocusType.meditation:
        return 'Quiet reflection and listening';
      case FocusType.generalPrayer:
        return 'General prayer time';
      case FocusType.specificPrayer:
        return 'Pray for a specific request';
      case FocusType.worship:
        return 'Praise and worship time';
      case FocusType.journaling:
        return 'Write your thoughts and prayers';
    }
  }

  String get icon {
    switch (this) {
      case FocusType.bibleStudy:
        return 'book-open';
      case FocusType.meditation:
        return 'brain';
      case FocusType.generalPrayer:
        return 'hand-metal';
      case FocusType.specificPrayer:
        return 'heart-handshake';
      case FocusType.worship:
        return 'music';
      case FocusType.journaling:
        return 'pencil';
    }
  }

  /// Database enum value (snake_case for Postgres).
  String get dbValue {
    switch (this) {
      case FocusType.bibleStudy:
        return 'bible_study';
      case FocusType.meditation:
        return 'meditation';
      case FocusType.generalPrayer:
        return 'general_prayer';
      case FocusType.specificPrayer:
        return 'specific_prayer';
      case FocusType.worship:
        return 'worship';
      case FocusType.journaling:
        return 'journaling';
    }
  }

  /// Parse from database value.
  static FocusType fromDbValue(String value) {
    switch (value) {
      case 'bible_study':
        return FocusType.bibleStudy;
      case 'meditation':
        return FocusType.meditation;
      case 'general_prayer':
        return FocusType.generalPrayer;
      case 'specific_prayer':
        return FocusType.specificPrayer;
      case 'worship':
        return FocusType.worship;
      case 'journaling':
        return FocusType.journaling;
      default:
        return FocusType.generalPrayer;
    }
  }
}

/// A completed focus session.
/// Backend-ready: All fields map to Supabase columns.
class FocusSession extends Equatable {
  final String id;
  final String userId;
  final FocusType type;
  final int? plannedDurationMinutes;
  final int actualDurationSeconds;
  final String? prayerId;
  final String? prayerTitle;
  final DateTime startedAt;
  final DateTime completedAt;
  final DateTime sessionDate;
  final String? notes;
  final bool wasCompleted;
  final bool isOpenEnded;
  final List<FocusAchievement> achievementsEarned;

  const FocusSession({
    required this.id,
    required this.userId,
    required this.type,
    this.plannedDurationMinutes,
    required this.actualDurationSeconds,
    this.prayerId,
    this.prayerTitle,
    required this.startedAt,
    required this.completedAt,
    DateTime? sessionDate,
    this.notes,
    this.wasCompleted = true,
    this.isOpenEnded = false,
    this.achievementsEarned = const [],
  }) : sessionDate = sessionDate ?? completedAt;

  /// Actual duration in minutes (rounded up)
  int get actualMinutes => (actualDurationSeconds / 60).ceil();

  /// For backwards compatibility
  int get durationMinutes => plannedDurationMinutes ?? actualMinutes;

  /// For display: "30 min" or "15 min (ended early)" or "25 min (open session)"
  String get durationDisplay {
    if (isOpenEnded) {
      return '$actualMinutes min';
    } else if (wasCompleted) {
      return '${plannedDurationMinutes ?? actualMinutes} min';
    } else {
      return '$actualMinutes min (ended early)';
    }
  }

  /// Get the highest achievement earned.
  FocusAchievement? get highestAchievement {
    if (achievementsEarned.isEmpty) return null;
    return achievementsEarned.last;
  }

  /// Create from Supabase JSON response.
  factory FocusSession.fromJson(Map<String, dynamic> json) {
    // Parse achievements from JSON array
    final achievementsJson = json['achievements_earned'] as List<dynamic>? ?? [];
    final achievements = achievementsJson
        .map((key) => FocusAchievement.fromDbKey(key as String))
        .whereType<FocusAchievement>()
        .toList();

    return FocusSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: FocusTypeExtension.fromDbValue(json['type'] as String),
      plannedDurationMinutes: json['planned_duration_minutes'] as int?,
      actualDurationSeconds: json['actual_duration_seconds'] as int? ?? 0,
      prayerId: json['prayer_id'] as String?,
      prayerTitle: json['prayer_title'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
      sessionDate: json['session_date'] != null
          ? DateTime.parse(json['session_date'] as String)
          : null,
      notes: json['notes'] as String?,
      wasCompleted: json['was_completed'] as bool? ?? true,
      isOpenEnded: json['is_open_ended'] as bool? ?? false,
      achievementsEarned: achievements,
    );
  }

  /// Convert to JSON for database INSERT (no id, Supabase generates UUID).
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'type': type.dbValue,
      'planned_duration_minutes': plannedDurationMinutes,
      'actual_duration_seconds': actualDurationSeconds,
      'is_open_ended': isOpenEnded,
      'was_completed': wasCompleted,
      'prayer_id': prayerId,
      'prayer_title': prayerTitle,
      'started_at': startedAt.toUtc().toIso8601String(),
      'completed_at': completedAt.toUtc().toIso8601String(),
      'session_date': completedAt.toIso8601String().split('T')[0],
      'notes': notes,
      'achievements_earned': achievementsEarned.map((a) => a.dbKey).toList(),
    };
  }

  /// Convert to full JSON (includes id for updates).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      ...toInsertJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  FocusSession copyWith({
    String? id,
    String? userId,
    FocusType? type,
    int? plannedDurationMinutes,
    bool clearPlannedDuration = false,
    int? actualDurationSeconds,
    String? prayerId,
    bool clearPrayerId = false,
    String? prayerTitle,
    bool clearPrayerTitle = false,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? sessionDate,
    String? notes,
    bool clearNotes = false,
    bool? wasCompleted,
    bool? isOpenEnded,
    List<FocusAchievement>? achievementsEarned,
  }) {
    return FocusSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      plannedDurationMinutes: clearPlannedDuration
          ? null
          : (plannedDurationMinutes ?? this.plannedDurationMinutes),
      actualDurationSeconds: actualDurationSeconds ?? this.actualDurationSeconds,
      prayerId: clearPrayerId ? null : (prayerId ?? this.prayerId),
      prayerTitle: clearPrayerTitle ? null : (prayerTitle ?? this.prayerTitle),
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      sessionDate: sessionDate ?? this.sessionDate,
      notes: clearNotes ? null : (notes ?? this.notes),
      wasCompleted: wasCompleted ?? this.wasCompleted,
      isOpenEnded: isOpenEnded ?? this.isOpenEnded,
      achievementsEarned: achievementsEarned ?? this.achievementsEarned,
    );
  }

  @override
  List<Object?> get props => [id, userId, type, plannedDurationMinutes, completedAt];
}

/// Stats for insights/analytics.
/// Cached in focus_stats table, auto-updated via database trigger.
class FocusStats extends Equatable {
  final String? userId;
  final int totalMinutesToday;
  final int totalMinutesThisWeek;
  final int totalMinutesThisMonth;
  final int totalMinutesAllTime;
  final int sessionsToday;
  final int sessionsThisWeek;
  final int totalSessions;
  final int currentStreak;
  final int longestStreak;
  final int longestSessionMinutes;
  final DateTime? lastSessionDate;
  final Map<FocusType, int> minutesByType;
  final Map<int, int> minutesByDayOfWeek;
  final Set<FocusAchievement> unlockedAchievements;

  const FocusStats({
    this.userId,
    this.totalMinutesToday = 0,
    this.totalMinutesThisWeek = 0,
    this.totalMinutesThisMonth = 0,
    this.totalMinutesAllTime = 0,
    this.sessionsToday = 0,
    this.sessionsThisWeek = 0,
    this.totalSessions = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.longestSessionMinutes = 0,
    this.lastSessionDate,
    this.minutesByType = const {},
    this.minutesByDayOfWeek = const {},
    this.unlockedAchievements = const {},
  });

  /// Check if an achievement is newly unlocked (not previously earned).
  bool isNewAchievement(FocusAchievement achievement) {
    return !unlockedAchievements.contains(achievement);
  }

  /// Get achievements that would be NEW for a given session duration.
  List<FocusAchievement> getNewAchievementsFor(int minutes) {
    return FocusAchievement.getAchievementsFor(minutes)
        .where((a) => !unlockedAchievements.contains(a))
        .toList();
  }

  /// Create from Supabase JSON response.
  factory FocusStats.fromJson(Map<String, dynamic> json) {
    // Parse minutes by type
    final typeJson = json['minutes_by_type'] as Map<String, dynamic>? ?? {};
    final minutesByType = <FocusType, int>{};
    typeJson.forEach((key, value) {
      final focusType = FocusTypeExtension.fromDbValue(key);
      minutesByType[focusType] = value as int? ?? 0;
    });

    // Parse minutes by day of week
    final dayJson = json['minutes_by_day_of_week'] as Map<String, dynamic>? ?? {};
    final minutesByDay = <int, int>{};
    dayJson.forEach((key, value) {
      minutesByDay[int.parse(key)] = value as int? ?? 0;
    });

    return FocusStats(
      userId: json['user_id'] as String?,
      totalMinutesToday: json['total_minutes_today'] as int? ?? 0,
      totalMinutesThisWeek: json['total_minutes_this_week'] as int? ?? 0,
      totalMinutesThisMonth: json['total_minutes_this_month'] as int? ?? 0,
      totalMinutesAllTime: json['total_minutes_all_time'] as int? ?? 0,
      sessionsToday: json['sessions_today'] as int? ?? 0,
      sessionsThisWeek: json['sessions_this_week'] as int? ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      longestSessionMinutes: json['longest_session_minutes'] as int? ?? 0,
      lastSessionDate: json['last_session_date'] != null
          ? DateTime.parse(json['last_session_date'] as String)
          : null,
      minutesByType: minutesByType,
      minutesByDayOfWeek: minutesByDay,
    );
  }

  /// Create a copy with updated fields.
  FocusStats copyWith({
    String? userId,
    int? totalMinutesToday,
    int? totalMinutesThisWeek,
    int? totalMinutesThisMonth,
    int? totalMinutesAllTime,
    int? sessionsToday,
    int? sessionsThisWeek,
    int? totalSessions,
    int? currentStreak,
    int? longestStreak,
    int? longestSessionMinutes,
    DateTime? lastSessionDate,
    Map<FocusType, int>? minutesByType,
    Map<int, int>? minutesByDayOfWeek,
    Set<FocusAchievement>? unlockedAchievements,
  }) {
    return FocusStats(
      userId: userId ?? this.userId,
      totalMinutesToday: totalMinutesToday ?? this.totalMinutesToday,
      totalMinutesThisWeek: totalMinutesThisWeek ?? this.totalMinutesThisWeek,
      totalMinutesThisMonth: totalMinutesThisMonth ?? this.totalMinutesThisMonth,
      totalMinutesAllTime: totalMinutesAllTime ?? this.totalMinutesAllTime,
      sessionsToday: sessionsToday ?? this.sessionsToday,
      sessionsThisWeek: sessionsThisWeek ?? this.sessionsThisWeek,
      totalSessions: totalSessions ?? this.totalSessions,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      longestSessionMinutes: longestSessionMinutes ?? this.longestSessionMinutes,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      minutesByType: minutesByType ?? this.minutesByType,
      minutesByDayOfWeek: minutesByDayOfWeek ?? this.minutesByDayOfWeek,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        totalMinutesToday,
        totalMinutesThisWeek,
        currentStreak,
        totalSessions,
        longestSessionMinutes,
      ];
}
