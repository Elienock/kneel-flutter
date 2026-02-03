import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:quick_church/core/utils/debug_logger.dart';
import 'package:quick_church/features/insights/domain/entities/user_session.dart';
import 'package:quick_church/features/insights/domain/repositories/i_insights_repository.dart';
import 'package:quick_church/features/insights/presentation/bloc/insights_state.dart';

/// Manages insights, sessions, and streak tracking.
@lazySingleton
class InsightsCubit extends Cubit<InsightsState> {
  final IInsightsRepository _repository;
  String? _currentUserId;

  InsightsCubit(this._repository) : super(const InsightsInitial());

  /// Initialize the cubit with a user ID.
  void init(String userId) {
    _currentUserId = userId;
    loadInsights();
  }

  /// Load all insights data.
  Future<void> loadInsights() async {
    if (_currentUserId == null) {
      emit(const InsightsError('User not authenticated'));
      return;
    }

    emit(const InsightsLoading());

    try {
      final results = await Future.wait([
        _repository.getStreakStats(_currentUserId!),
        _repository.getActivityHeatmap(_currentUserId!),
        _repository.getRecentSessions(_currentUserId!, days: 30),
      ]);

      emit(InsightsLoaded(
        streakStats: results[0] as StreakStats,
        heatmap: results[1] as Map<DateTime, DailyActivity>,
        recentSessions: results[2] as List<UserSession>,
      ));
    } catch (e) {
      DebugLogger.error('InsightsCubit.loadInsights', e);
      emit(InsightsError('Failed to load insights: $e'));
    }
  }

  /// Record a new session (called when Sacred Time completes).
  Future<StreakStats?> recordSession({
    required SessionType type,
    required int durationMinutes,
    required int actualDurationSeconds,
    required bool completed,
    bool prayerAnswered = false,
    String? noteId,
  }) async {
    if (_currentUserId == null) return null;

    try {
      final session = UserSession(
        id: const Uuid().v4(),
        userId: _currentUserId!,
        type: type,
        durationMinutes: durationMinutes,
        actualDurationSeconds: actualDurationSeconds,
        sessionDate: DateTime.now(),
        completed: completed,
        prayerAnswered: prayerAnswered,
        noteId: noteId,
        createdAt: DateTime.now(),
      );

      final recorded = await _repository.recordSession(session);

      // If prayer was answered, increment the counter
      if (prayerAnswered) {
        await _repository.incrementAnsweredPrayers(_currentUserId!);
      }

      // Get updated stats
      final newStats = await _repository.getStreakStats(_currentUserId!);

      emit(SessionRecorded(session: recorded, newStats: newStats));

      // Reload full insights data
      await loadInsights();

      return newStats;
    } catch (e) {
      DebugLogger.error('InsightsCubit.recordSession', e);
      return null;
    }
  }

  /// Get current streak stats (cached or fresh).
  Future<StreakStats> getStreakStats() async {
    if (_currentUserId == null) return const StreakStats();

    final currentState = state;
    if (currentState is InsightsLoaded) {
      return currentState.streakStats;
    }

    try {
      return await _repository.getStreakStats(_currentUserId!);
    } catch (e) {
      DebugLogger.error('InsightsCubit.getStreakStats', e);
      return const StreakStats();
    }
  }

  /// Get activity heatmap for a date range.
  Future<Map<DateTime, DailyActivity>> getHeatmap({int days = 365}) async {
    if (_currentUserId == null) return {};

    try {
      return await _repository.getActivityHeatmap(_currentUserId!, days: days);
    } catch (e) {
      DebugLogger.error('InsightsCubit.getHeatmap', e);
      return {};
    }
  }

  /// Get sessions for a specific date.
  Future<List<UserSession>> getSessionsForDate(DateTime date) async {
    if (_currentUserId == null) return [];

    try {
      return await _repository.getSessionsForDate(_currentUserId!, date);
    } catch (e) {
      DebugLogger.error('InsightsCubit.getSessionsForDate', e);
      return [];
    }
  }

  /// Mark a prayer as answered (increments counter).
  Future<void> markPrayerAnswered() async {
    if (_currentUserId == null) return;

    try {
      await _repository.incrementAnsweredPrayers(_currentUserId!);
      await loadInsights();
    } catch (e) {
      DebugLogger.error('InsightsCubit.markPrayerAnswered', e);
    }
  }

  /// Clear state (on logout).
  void clear() {
    _currentUserId = null;
    emit(const InsightsInitial());
  }
}
