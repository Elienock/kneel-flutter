import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:quick_church/features/prayer/data/models/prayer_session_model.dart';
import 'package:quick_church/features/prayer/presentation/bloc/session_state.dart';

/// Cubit for managing prayer session tracking and calendar data.
@injectable
class SessionCubit extends Cubit<SessionState> {
  final Box<PrayerSessionModel> _sessionBox;
  final Uuid _uuid;

  SessionCubit(this._sessionBox, this._uuid) : super(const SessionInitial());

  /// Loads all sessions and calculates streaks.
  Future<void> loadSessions() async {
    emit(const SessionLoading());

    try {
      final sessions = _sessionBox.values.toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

      final streaks = _calculateStreaks(sessions);
      final totalDeepSessions = sessions.where((s) => s.isDeepSession).length;
      final totalMinutesPrayed =
          sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;

      // Check for bonus streak (at least one 10-min session today)
      final today = normalizeDate(DateTime.now());
      final todaySessions = sessions.where((s) => normalizeDate(s.date) == today);
      final hasBonusStreak = todaySessions.any((s) => s.isDeepSession);

      emit(SessionLoaded(
        sessions: sessions,
        currentStreak: streaks.$1,
        bestStreak: streaks.$2,
        totalDeepSessions: totalDeepSessions,
        totalMinutesPrayed: totalMinutesPrayed,
        hasBonusStreak: hasBonusStreak,
      ));
    } catch (e) {
      emit(SessionError('Failed to load sessions: $e'));
    }
  }

  /// Records a completed prayer session.
  Future<void> recordSession({
    required int durationSeconds,
    required DateTime startedAt,
    required DateTime endedAt,
    required int prayersPrayed,
    String? notes,
  }) async {
    try {
      final session = PrayerSessionModel(
        id: _uuid.v4(),
        date: normalizeDate(startedAt),
        durationSeconds: durationSeconds,
        startedAt: startedAt,
        endedAt: endedAt,
        isDeepSession: durationSeconds >= 600, // 10 minutes = 600 seconds
        prayersPrayed: prayersPrayed,
        notes: notes,
      );

      await _sessionBox.put(session.id, session);
      HapticFeedback.heavyImpact();

      // Reload to recalculate streaks
      await loadSessions();

      if (state is SessionLoaded) {
        final currentState = state as SessionLoaded;
        final message = session.isDeepSession
            ? 'Deep Prayer Session Completed!'
            : 'Prayer Session Recorded';
        emit(currentState.copyWith(successMessage: message));
      }
    } catch (e) {
      emit(SessionError('Failed to record session: $e'));
    }
  }

  /// Calculates current streak and best streak from sessions.
  /// Returns (currentStreak, bestStreak).
  (int, int) _calculateStreaks(List<PrayerSessionModel> sessions) {
    if (sessions.isEmpty) return (0, 0);

    // Get unique days with sessions
    final uniqueDays = <DateTime>{};
    for (final session in sessions) {
      uniqueDays.add(normalizeDate(session.date));
    }

    final sortedDays = uniqueDays.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    if (sortedDays.isEmpty) return (0, 0);

    // Calculate current streak
    int currentStreak = 0;
    final today = normalizeDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if we have activity today or yesterday to start counting
    if (sortedDays.contains(today) || sortedDays.contains(yesterday)) {
      DateTime checkDate = sortedDays.contains(today) ? today : yesterday;

      while (sortedDays.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // Calculate best streak
    int bestStreak = 0;
    int tempStreak = 0;
    DateTime? previousDay;

    // Sort oldest to newest for best streak calculation
    final chronologicalDays = sortedDays.reversed.toList();

    for (final day in chronologicalDays) {
      if (previousDay == null) {
        tempStreak = 1;
      } else {
        final expectedNext = previousDay.add(const Duration(days: 1));
        if (day == expectedNext) {
          tempStreak++;
        } else {
          bestStreak = tempStreak > bestStreak ? tempStreak : bestStreak;
          tempStreak = 1;
        }
      }
      previousDay = day;
    }
    bestStreak = tempStreak > bestStreak ? tempStreak : bestStreak;

    return (currentStreak, bestStreak);
  }

  /// Clears the success message.
  void clearMessage() {
    if (state is SessionLoaded) {
      emit((state as SessionLoaded).clearMessage());
    }
  }

  /// Gets sessions for a specific month (for calendar display).
  List<PrayerSessionModel> getSessionsForMonth(DateTime month) {
    if (state is! SessionLoaded) return [];

    final sessions = (state as SessionLoaded).sessions;
    return sessions.where((s) {
      return s.date.year == month.year && s.date.month == month.month;
    }).toList();
  }

  /// Checks if a specific day has any prayer activity.
  bool hasActivityOnDay(DateTime day) {
    if (state is! SessionLoaded) return false;
    return (state as SessionLoaded).hasActivityOnDay(day);
  }

  /// Checks if a specific day has a deep session.
  bool hasDeepSessionOnDay(DateTime day) {
    if (state is! SessionLoaded) return false;
    return (state as SessionLoaded).hasDeepSessionOnDay(day);
  }
}
