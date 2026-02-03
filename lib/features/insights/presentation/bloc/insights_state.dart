import 'package:equatable/equatable.dart';
import 'package:quick_church/features/insights/domain/entities/user_session.dart';

/// Base state for Insights feature.
abstract class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

/// Loading state while fetching insights data.
class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

/// Successfully loaded insights data.
class InsightsLoaded extends InsightsState {
  final StreakStats streakStats;
  final Map<DateTime, DailyActivity> heatmap;
  final List<UserSession> recentSessions;

  const InsightsLoaded({
    required this.streakStats,
    required this.heatmap,
    required this.recentSessions,
  });

  InsightsLoaded copyWith({
    StreakStats? streakStats,
    Map<DateTime, DailyActivity>? heatmap,
    List<UserSession>? recentSessions,
  }) {
    return InsightsLoaded(
      streakStats: streakStats ?? this.streakStats,
      heatmap: heatmap ?? this.heatmap,
      recentSessions: recentSessions ?? this.recentSessions,
    );
  }

  @override
  List<Object?> get props => [streakStats, heatmap, recentSessions];
}

/// Error state when loading fails.
class InsightsError extends InsightsState {
  final String message;

  const InsightsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State emitted after a session is recorded.
class SessionRecorded extends InsightsState {
  final UserSession session;
  final StreakStats newStats;

  const SessionRecorded({
    required this.session,
    required this.newStats,
  });

  @override
  List<Object?> get props => [session, newStats];
}
