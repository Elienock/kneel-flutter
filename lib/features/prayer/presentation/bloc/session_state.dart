import 'package:equatable/equatable.dart';
import 'package:quick_church/features/prayer/data/models/prayer_session_model.dart';

/// Base state for session management.
sealed class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any sessions are loaded.
class SessionInitial extends SessionState {
  const SessionInitial();
}

/// Loading state while fetching session data.
class SessionLoading extends SessionState {
  const SessionLoading();
}

/// Loaded state with all session data.
class SessionLoaded extends SessionState {
  final List<PrayerSessionModel> sessions;
  final int currentStreak;
  final int bestStreak;
  final int totalDeepSessions;
  final int totalMinutesPrayed;
  final bool hasBonusStreak;
  final String? successMessage;

  const SessionLoaded({
    required this.sessions,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalDeepSessions,
    required this.totalMinutesPrayed,
    this.hasBonusStreak = false,
    this.successMessage,
  });

  /// Get sessions for a specific day.
  List<PrayerSessionModel> getSessionsForDay(DateTime day) {
    final normalized = normalizeDate(day);
    return sessions.where((s) => normalizeDate(s.date) == normalized).toList();
  }

  /// Check if a day has any activity.
  bool hasActivityOnDay(DateTime day) {
    return getSessionsForDay(day).isNotEmpty;
  }

  /// Check if a day has a deep session (10+ minutes total).
  bool hasDeepSessionOnDay(DateTime day) {
    final daySessions = getSessionsForDay(day);
    if (daySessions.isEmpty) return false;
    final totalMinutes = daySessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    ) ~/ 60;
    return totalMinutes >= 10;
  }

  /// Get total minutes for a specific day.
  int getMinutesForDay(DateTime day) {
    final daySessions = getSessionsForDay(day);
    return daySessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) ~/ 60;
  }

  SessionLoaded copyWith({
    List<PrayerSessionModel>? sessions,
    int? currentStreak,
    int? bestStreak,
    int? totalDeepSessions,
    int? totalMinutesPrayed,
    bool? hasBonusStreak,
    String? successMessage,
  }) {
    return SessionLoaded(
      sessions: sessions ?? this.sessions,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalDeepSessions: totalDeepSessions ?? this.totalDeepSessions,
      totalMinutesPrayed: totalMinutesPrayed ?? this.totalMinutesPrayed,
      hasBonusStreak: hasBonusStreak ?? this.hasBonusStreak,
      successMessage: successMessage,
    );
  }

  SessionLoaded clearMessage() {
    return copyWith(successMessage: null);
  }

  @override
  List<Object?> get props => [
        sessions,
        currentStreak,
        bestStreak,
        totalDeepSessions,
        totalMinutesPrayed,
        hasBonusStreak,
        successMessage,
      ];
}

/// Error state when something goes wrong.
class SessionError extends SessionState {
  final String message;

  const SessionError(this.message);

  @override
  List<Object?> get props => [message];
}
