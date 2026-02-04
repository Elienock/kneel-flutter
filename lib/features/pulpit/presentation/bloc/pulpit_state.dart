import 'package:equatable/equatable.dart';
import 'package:quick_church/features/pulpit/domain/entities/pulpit_prayer_group.dart';

enum PulpitStatus { initial, loading, loaded, error }

/// State for the pulpit feature.
class PulpitState extends Equatable {
  final PulpitStatus status;
  final List<PulpitPrayerGroup> groups;
  final PulpitPrayerGroup? selectedGroup;
  final String? errorMessage;

  const PulpitState({
    this.status = PulpitStatus.initial,
    this.groups = const [],
    this.selectedGroup,
    this.errorMessage,
  });

  PulpitState copyWith({
    PulpitStatus? status,
    List<PulpitPrayerGroup>? groups,
    PulpitPrayerGroup? selectedGroup,
    String? errorMessage,
    bool clearSelectedGroup = false,
  }) {
    return PulpitState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      selectedGroup: clearSelectedGroup ? null : (selectedGroup ?? this.selectedGroup),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, groups, selectedGroup, errorMessage];
}

/// State for an active pulpit session.
class PulpitSessionState extends Equatable {
  final PulpitPrayerGroup group;
  final int currentIndex;
  final int elapsedSeconds; // Time on current point
  final bool isPaused;
  final bool isComplete;

  const PulpitSessionState({
    required this.group,
    this.currentIndex = 0,
    this.elapsedSeconds = 0,
    this.isPaused = false,
    this.isComplete = false,
  });

  /// Current prayer point.
  PulpitPrayerPoint? get currentPoint {
    if (group.points.isEmpty || currentIndex >= group.points.length) {
      return null;
    }
    return group.points[currentIndex];
  }

  /// Next prayer point (for preview).
  PulpitPrayerPoint? get nextPoint {
    final nextIdx = currentIndex + 1;
    if (nextIdx >= group.points.length) return null;
    return group.points[nextIdx];
  }

  /// Previous prayer point exists?
  bool get hasPrevious => currentIndex > 0;

  /// Next prayer point exists?
  bool get hasNext => currentIndex < group.points.length - 1;

  /// Progress as fraction (0.0 to 1.0).
  double get progress {
    if (group.points.isEmpty) return 0;
    return (currentIndex + 1) / group.points.length;
  }

  /// Formatted elapsed time string.
  String get elapsedTimeFormatted {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Time remaining (for auto-advance mode).
  int get remainingSeconds {
    if (group.autoAdvance) {
      return (group.secondsPerPoint - elapsedSeconds).clamp(0, group.secondsPerPoint);
    }
    return 0;
  }

  /// Formatted remaining time string.
  String get remainingTimeFormatted {
    final remaining = remainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Timer progress (for auto-advance visual).
  double get timerProgress {
    if (!group.autoAdvance || group.secondsPerPoint == 0) return 0;
    return elapsedSeconds / group.secondsPerPoint;
  }

  PulpitSessionState copyWith({
    PulpitPrayerGroup? group,
    int? currentIndex,
    int? elapsedSeconds,
    bool? isPaused,
    bool? isComplete,
  }) {
    return PulpitSessionState(
      group: group ?? this.group,
      currentIndex: currentIndex ?? this.currentIndex,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  List<Object?> get props => [group, currentIndex, elapsedSeconds, isPaused, isComplete];
}
