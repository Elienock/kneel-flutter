import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quick_church/core/utils/debug_logger.dart';
import 'package:quick_church/features/insights/domain/entities/user_session.dart';
import 'package:quick_church/features/insights/domain/repositories/i_insights_repository.dart';

/// Supabase implementation of [IInsightsRepository].
@LazySingleton(as: IInsightsRepository)
class SupabaseInsightsRepository implements IInsightsRepository {
  SupabaseClient get _client => Supabase.instance.client;

  // ============================================================================
  // SESSION OPERATIONS
  // ============================================================================

  @override
  Future<UserSession> recordSession(UserSession session) async {
    try {
      final response = await _client
          .from('user_sessions')
          .insert(session.toInsertJson())
          .select()
          .single();

      DebugLogger.log('Recorded session: ${session.type.label}');

      // Update streak after recording session
      await _updateStreakAfterSession(session.userId);

      return UserSession.fromJson(response);
    } catch (e) {
      DebugLogger.error('SupabaseInsightsRepository.recordSession', e);
      rethrow;
    }
  }

  @override
  Future<List<UserSession>> getSessionsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .gte('session_date', startDate.toIso8601String().split('T')[0])
          .lte('session_date', endDate.toIso8601String().split('T')[0])
          .order('session_date', ascending: false);

      return (response as List).map((json) => UserSession.fromJson(json)).toList();
    } catch (e) {
      DebugLogger.error('SupabaseInsightsRepository.getSessionsInRange', e);
      return [];
    }
  }

  @override
  Future<List<UserSession>> getSessionsForDate(String userId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _client
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .eq('session_date', dateStr)
          .order('created_at', ascending: false);

      return (response as List).map((json) => UserSession.fromJson(json)).toList();
    } catch (e) {
      DebugLogger.error('SupabaseInsightsRepository.getSessionsForDate', e);
      return [];
    }
  }

  @override
  Future<List<UserSession>> getRecentSessions(String userId, {int days = 365}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .gte('session_date', startDate.toIso8601String().split('T')[0])
          .order('session_date', ascending: false);

      return (response as List).map((json) => UserSession.fromJson(json)).toList();
    } catch (e) {
      DebugLogger.error('SupabaseInsightsRepository.getRecentSessions', e);
      return [];
    }
  }

  // ============================================================================
  // STATISTICS OPERATIONS
  // ============================================================================

  @override
  Future<Map<DateTime, DailyActivity>> getActivityHeatmap(
    String userId, {
    int days = 365,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final sessions = await getSessionsInRange(userId, startDate, DateTime.now());

      // Group sessions by date
      final Map<DateTime, List<UserSession>> grouped = {};
      for (final session in sessions) {
        final dateKey = DateTime(
          session.sessionDate.year,
          session.sessionDate.month,
          session.sessionDate.day,
        );
        grouped.putIfAbsent(dateKey, () => []).add(session);
      }

      // Convert to DailyActivity
      final Map<DateTime, DailyActivity> heatmap = {};
      grouped.forEach((date, daySessions) {
        heatmap[date] = DailyActivity(
          date: date,
          sessionCount: daySessions.length,
          totalMinutes: daySessions.fold(0, (sum, s) => sum + s.durationMinutes),
          types: daySessions.map((s) => s.type).toSet().toList(),
        );
      });

      return heatmap;
    } catch (e) {
      DebugLogger.error('SupabaseInsightsRepository.getActivityHeatmap', e);
      return {};
    }
  }

  @override
  Future<StreakStats> getStreakStats(String userId) async {
    try {
      final sessions = await getRecentSessions(userId, days: 365);

      if (sessions.isEmpty) {
        return const StreakStats();
      }

      // Calculate statistics
      final totalSessions = sessions.length;
      final totalMinutes = sessions.fold(0, (sum, s) => sum + s.durationMinutes);
      final answeredPrayers = sessions.where((s) => s.prayerAnswered).length;

      // Get unique dates (sorted descending)
      final uniqueDates = sessions
          .map((s) => DateTime(s.sessionDate.year, s.sessionDate.month, s.sessionDate.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      // Calculate current streak
      int currentStreak = 0;
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      if (uniqueDates.isNotEmpty) {
        final mostRecent = uniqueDates.first;
        final daysSinceLastSession = todayDate.difference(mostRecent).inDays;

        // Streak is active if last session was today or yesterday
        if (daysSinceLastSession <= 1) {
          currentStreak = 1;
          DateTime checkDate = mostRecent.subtract(const Duration(days: 1));

          for (int i = 1; i < uniqueDates.length; i++) {
            final sessionDate = uniqueDates[i];
            if (sessionDate == checkDate) {
              currentStreak++;
              checkDate = checkDate.subtract(const Duration(days: 1));
            } else if (sessionDate.isBefore(checkDate)) {
              break;
            }
          }
        }
      }

      // Calculate longest streak
      int longestStreak = 0;
      int tempStreak = 0;
      DateTime? prevDate;

      for (final date in uniqueDates.reversed) {
        if (prevDate == null) {
          tempStreak = 1;
        } else {
          final diff = date.difference(prevDate).inDays;
          if (diff == 1) {
            tempStreak++;
          } else {
            if (tempStreak > longestStreak) {
              longestStreak = tempStreak;
            }
            tempStreak = 1;
          }
        }
        prevDate = date;
      }
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }

      return StreakStats(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        totalSessions: totalSessions,
        totalMinutes: totalMinutes,
        answeredPrayers: answeredPrayers,
        lastSessionDate: uniqueDates.isNotEmpty ? uniqueDates.first : null,
      );
    } catch (e) {
      DebugLogger.error('SupabaseInsightsRepository.getStreakStats', e);
      return const StreakStats();
    }
  }

  @override
  Future<int> getAnsweredPrayersCount(String userId) async {
    try {
      final response = await _client
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .eq('prayer_answered', true);

      return (response as List).length;
    } catch (e) {
      DebugLogger.error('SupabaseInsightsRepository.getAnsweredPrayersCount', e);
      return 0;
    }
  }

  // ============================================================================
  // PROFILE OPERATIONS
  // ============================================================================

  @override
  Future<void> incrementAnsweredPrayers(String userId) async {
    try {
      // Get current count
      final response = await _client
          .from('profiles')
          .select('answered_prayers_count')
          .eq('id', userId)
          .maybeSingle();

      final currentCount = (response?['answered_prayers_count'] as int?) ?? 0;

      // Increment
      await _client
          .from('profiles')
          .update({
            'answered_prayers_count': currentCount + 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      DebugLogger.log('Incremented answered prayers for user: $userId');
    } catch (e) {
      DebugLogger.error('SupabaseInsightsRepository.incrementAnsweredPrayers', e);
      // Don't rethrow - this is not critical
    }
  }

  @override
  Future<void> updateStreak(String userId, int streak) async {
    try {
      await _client
          .from('profiles')
          .update({
            'current_streak': streak,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      DebugLogger.log('Updated streak for user: $userId to $streak');
    } catch (e) {
      DebugLogger.error('SupabaseInsightsRepository.updateStreak', e);
      // Don't rethrow - this is not critical
    }
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  Future<void> _updateStreakAfterSession(String userId) async {
    try {
      final stats = await getStreakStats(userId);
      await updateStreak(userId, stats.currentStreak);
    } catch (e) {
      DebugLogger.error('SupabaseInsightsRepository._updateStreakAfterSession', e);
    }
  }
}
