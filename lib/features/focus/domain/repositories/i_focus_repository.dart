import '../entities/focus_session.dart';

/// Interface for focus session data operations.
/// Implementations: SupabaseFocusRepository (production), MockFocusRepository (testing)
abstract class IFocusRepository {
  /// Save a completed focus session.
  Future<FocusSession> saveSession({
    required FocusType type,
    int? plannedDurationMinutes,
    required int actualDurationSeconds,
    String? prayerId,
    String? prayerTitle,
    required DateTime startedAt,
    String? notes,
    required bool wasCompleted,
    bool isOpenEnded = false,
  });

  /// Get all sessions for current user, ordered by most recent.
  Future<List<FocusSession>> getSessions({int limit = 50});

  /// Get sessions for a specific date range.
  Future<List<FocusSession>> getSessionsInRange(DateTime start, DateTime end);

  /// Get today's sessions.
  Future<List<FocusSession>> getTodaySessions();

  /// Get this week's sessions (starting from Sunday).
  Future<List<FocusSession>> getThisWeekSessions();

  /// Get focus stats (cached for performance).
  Future<FocusStats> getStats();

  /// Get heatmap data for a date range (for GitHub-style activity visualization).
  Future<Map<DateTime, FocusDailyActivity>> getActivityHeatmap({int days = 365});

  /// Get all unlocked achievements.
  Future<Set<FocusAchievement>> getUnlockedAchievements();

  /// Unlock a new achievement.
  Future<void> unlockAchievement(FocusAchievement achievement, String? sessionId);

  /// Delete a session.
  Future<void> deleteSession(String sessionId);

  /// Stream of sessions (real-time updates).
  Stream<List<FocusSession>> watchSessions({int limit = 20});

  /// Stream of stats (real-time updates).
  Stream<FocusStats> watchStats();
}

/// Daily activity data for heatmap visualization.
class FocusDailyActivity {
  final DateTime date;
  final int sessionCount;
  final int totalMinutes;
  final List<FocusType> types;

  const FocusDailyActivity({
    required this.date,
    required this.sessionCount,
    required this.totalMinutes,
    required this.types,
  });

  /// Activity level 0-4 for GitHub-style heatmap colors.
  int get activityLevel {
    if (sessionCount == 0) return 0;
    if (totalMinutes < 10) return 1;
    if (totalMinutes < 20) return 2;
    if (totalMinutes < 40) return 3;
    return 4;
  }

  /// Whether this day has any activity.
  bool get hasActivity => sessionCount > 0;
}
