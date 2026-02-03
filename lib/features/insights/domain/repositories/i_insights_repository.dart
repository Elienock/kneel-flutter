import 'package:quick_church/features/insights/domain/entities/user_session.dart';

/// Abstract interface for Insights data operations.
abstract class IInsightsRepository {
  // ============================================================================
  // SESSION OPERATIONS
  // ============================================================================

  /// Records a new session.
  Future<UserSession> recordSession(UserSession session);

  /// Gets all sessions for a user within a date range.
  Future<List<UserSession>> getSessionsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Gets sessions for a specific date.
  Future<List<UserSession>> getSessionsForDate(String userId, DateTime date);

  /// Gets the user's session history (last N days).
  Future<List<UserSession>> getRecentSessions(String userId, {int days = 365});

  // ============================================================================
  // STATISTICS OPERATIONS
  // ============================================================================

  /// Gets daily activity data for heatmap (last year).
  Future<Map<DateTime, DailyActivity>> getActivityHeatmap(
    String userId, {
    int days = 365,
  });

  /// Gets streak statistics.
  Future<StreakStats> getStreakStats(String userId);

  /// Gets total answered prayers count.
  Future<int> getAnsweredPrayersCount(String userId);

  // ============================================================================
  // PROFILE OPERATIONS
  // ============================================================================

  /// Increments the answered prayers count in profile.
  Future<void> incrementAnsweredPrayers(String userId);

  /// Updates the current streak in profile.
  Future<void> updateStreak(String userId, int streak);
}
