import 'package:equatable/equatable.dart';
import '../../domain/entities/focus_session.dart';

/// State for the focus feature.
class FocusState extends Equatable {
  final List<FocusSession> sessions;
  final FocusStats stats;
  final bool isLoading;
  final String? error;

  // Active timer state
  final bool isTimerRunning;
  final bool isTimerPaused;
  final FocusType? activeType;
  final String? activePrayerId;
  final String? activePrayerTitle;
  final int plannedDurationSeconds; // 0 for open-ended
  final int elapsedSeconds;
  final DateTime? timerStartedAt;
  final bool isOpenEnded; // True = no time limit, counts up

  const FocusState({
    this.sessions = const [],
    this.stats = const FocusStats(),
    this.isLoading = false,
    this.error,
    this.isTimerRunning = false,
    this.isTimerPaused = false,
    this.activeType,
    this.activePrayerId,
    this.activePrayerTitle,
    this.plannedDurationSeconds = 0,
    this.elapsedSeconds = 0,
    this.timerStartedAt,
    this.isOpenEnded = false,
  });

  /// Remaining seconds on the timer (0 for open-ended).
  int get remainingSeconds => isOpenEnded
      ? 0
      : (plannedDurationSeconds - elapsedSeconds).clamp(0, plannedDurationSeconds);

  /// Progress from 0.0 to 1.0 (always 0 for open-ended).
  double get progress => isOpenEnded
      ? 0
      : (plannedDurationSeconds > 0 ? elapsedSeconds / plannedDurationSeconds : 0);

  /// Is the timer complete? (Never true for open-ended).
  bool get isTimerComplete => !isOpenEnded &&
      isTimerRunning &&
      plannedDurationSeconds > 0 &&
      elapsedSeconds >= plannedDurationSeconds;

  /// Format remaining time as MM:SS (for timed sessions).
  String get remainingTimeDisplay {
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format elapsed time as MM:SS.
  String get elapsedTimeDisplay {
    final mins = elapsedSeconds ~/ 60;
    final secs = elapsedSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Elapsed time in minutes.
  int get elapsedMinutes => elapsedSeconds ~/ 60;

  /// Get current achievement level based on elapsed time.
  FocusAchievement? get currentAchievement =>
      FocusAchievement.getHighestFor(elapsedMinutes);

  /// Get next achievement to reach.
  FocusAchievement? get nextAchievement =>
      FocusAchievement.getNextFor(elapsedMinutes);

  FocusState copyWith({
    List<FocusSession>? sessions,
    FocusStats? stats,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isTimerRunning,
    bool? isTimerPaused,
    FocusType? activeType,
    bool clearActiveType = false,
    String? activePrayerId,
    bool clearActivePrayerId = false,
    String? activePrayerTitle,
    bool clearActivePrayerTitle = false,
    int? plannedDurationSeconds,
    int? elapsedSeconds,
    DateTime? timerStartedAt,
    bool clearTimerStartedAt = false,
    bool? isOpenEnded,
  }) {
    return FocusState(
      sessions: sessions ?? this.sessions,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isTimerPaused: isTimerPaused ?? this.isTimerPaused,
      activeType: clearActiveType ? null : (activeType ?? this.activeType),
      activePrayerId:
          clearActivePrayerId ? null : (activePrayerId ?? this.activePrayerId),
      activePrayerTitle: clearActivePrayerTitle
          ? null
          : (activePrayerTitle ?? this.activePrayerTitle),
      plannedDurationSeconds:
          plannedDurationSeconds ?? this.plannedDurationSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      timerStartedAt: clearTimerStartedAt
          ? null
          : (timerStartedAt ?? this.timerStartedAt),
      isOpenEnded: isOpenEnded ?? this.isOpenEnded,
    );
  }

  @override
  List<Object?> get props => [
        sessions,
        stats,
        isLoading,
        error,
        isTimerRunning,
        isTimerPaused,
        activeType,
        activePrayerId,
        plannedDurationSeconds,
        elapsedSeconds,
        isOpenEnded,
      ];
}
