import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quick_church/core/utils/kneel_logger.dart';
import 'package:quick_church/features/insights/domain/entities/user_session.dart';
import 'package:quick_church/features/insights/domain/repositories/i_insights_repository.dart';
import '../../domain/entities/focus_session.dart';
import '../../domain/repositories/i_focus_repository.dart';
import 'focus_state.dart';

/// Cubit for managing focus sessions and timer.
/// Production-ready with Supabase integration via IFocusRepository.
/// Also syncs to Insights for unified heatmap tracking.
@injectable
class FocusCubit extends Cubit<FocusState> {
  final IFocusRepository _repository;
  final IInsightsRepository _insightsRepository;
  Timer? _timer;

  /// Callback to increment prayer count when specific prayer is used.
  /// This will be set from outside to integrate with PrayerCubit.
  void Function(String prayerId)? onPrayerCompleted;

  FocusCubit(this._repository, this._insightsRepository) : super(const FocusState());

  /// Load sessions and stats.
  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final sessions = await _repository.getSessions();
      final stats = await _repository.getStats();

      emit(state.copyWith(
        sessions: sessions,
        stats: stats,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load focus data: $e',
      ));
    }
  }

  /// Start a focus timer.
  /// Set [durationMinutes] to 0 or null for open-ended mode.
  void startTimer({
    required FocusType type,
    int? durationMinutes,
    String? prayerId,
    String? prayerTitle,
  }) {
    // Cancel any existing timer
    _timer?.cancel();

    final isOpenEnded = durationMinutes == null || durationMinutes == 0;

    emit(state.copyWith(
      isTimerRunning: true,
      isTimerPaused: false,
      activeType: type,
      activePrayerId: prayerId,
      activePrayerTitle: prayerTitle,
      plannedDurationSeconds: isOpenEnded ? 0 : durationMinutes * 60,
      elapsedSeconds: 0,
      timerStartedAt: DateTime.now(),
      isOpenEnded: isOpenEnded,
    ));

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isTimerPaused) {
        final newElapsed = state.elapsedSeconds + 1;

        // For open-ended mode, just keep counting
        if (state.isOpenEnded) {
          emit(state.copyWith(elapsedSeconds: newElapsed));
        } else if (newElapsed >= state.plannedDurationSeconds) {
          // Timer complete (timed mode only)
          timer.cancel();
          _onTimerComplete();
        } else {
          emit(state.copyWith(elapsedSeconds: newElapsed));
        }
      }
    });
  }

  /// Pause the timer.
  void pauseTimer() {
    if (state.isTimerRunning && !state.isTimerPaused) {
      emit(state.copyWith(isTimerPaused: true));
    }
  }

  /// Resume the timer.
  void resumeTimer() {
    if (state.isTimerRunning && state.isTimerPaused) {
      emit(state.copyWith(isTimerPaused: false));
    }
  }

  /// End the timer early.
  Future<void> endTimerEarly() async {
    _timer?.cancel();
    await _saveSession(wasCompleted: false);
  }

  /// Called when timer naturally completes.
  Future<void> _onTimerComplete() async {
    emit(state.copyWith(
      elapsedSeconds: state.plannedDurationSeconds,
    ));
    await _saveSession(wasCompleted: true);
  }

  /// Manually mark session as complete (for when user acknowledges completion).
  Future<void> completeSession({String? notes}) async {
    if (state.activeType == null) return;

    // If specific prayer, notify PrayerCubit
    if (state.activeType == FocusType.specificPrayer &&
        state.activePrayerId != null) {
      onPrayerCompleted?.call(state.activePrayerId!);
    }

    // Determine if session was "completed" - for timed: finished full time, for open: always true
    final wasCompleted = state.isOpenEnded ||
        state.elapsedSeconds >= state.plannedDurationSeconds;

    // Save the session
    try {
      final session = await _repository.saveSession(
        type: state.activeType!,
        plannedDurationMinutes: state.isOpenEnded
            ? null
            : state.plannedDurationSeconds ~/ 60,
        actualDurationSeconds: state.elapsedSeconds,
        prayerId: state.activePrayerId,
        prayerTitle: state.activePrayerTitle,
        startedAt: state.timerStartedAt ?? DateTime.now(),
        notes: notes,
        wasCompleted: wasCompleted,
        isOpenEnded: state.isOpenEnded,
      );

      // Also sync to Insights for unified heatmap
      await _syncToInsights(session);

      // Update sessions list and stats
      final sessions = [session, ...state.sessions];
      final stats = await _repository.getStats();

      emit(state.copyWith(
        sessions: sessions,
        stats: stats,
        isTimerRunning: false,
        isTimerPaused: false,
        clearActiveType: true,
        clearActivePrayerId: true,
        clearActivePrayerTitle: true,
        plannedDurationSeconds: 0,
        elapsedSeconds: 0,
        clearTimerStartedAt: true,
        isOpenEnded: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to save session: $e'));
    }
  }

  /// Save session internally.
  Future<void> _saveSession({required bool wasCompleted}) async {
    // Don't save if nothing was recorded
    if (state.elapsedSeconds < 10 || state.activeType == null) {
      _resetTimer();
      return;
    }

    // If specific prayer, notify PrayerCubit
    if (state.activeType == FocusType.specificPrayer &&
        state.activePrayerId != null) {
      onPrayerCompleted?.call(state.activePrayerId!);
    }

    try {
      final session = await _repository.saveSession(
        type: state.activeType!,
        plannedDurationMinutes: state.isOpenEnded
            ? null
            : state.plannedDurationSeconds ~/ 60,
        actualDurationSeconds: state.elapsedSeconds,
        prayerId: state.activePrayerId,
        prayerTitle: state.activePrayerTitle,
        startedAt: state.timerStartedAt ?? DateTime.now(),
        notes: null,
        wasCompleted: wasCompleted,
        isOpenEnded: state.isOpenEnded,
      );

      // Also sync to Insights for unified heatmap
      await _syncToInsights(session);

      // Update sessions list and stats
      final sessions = [session, ...state.sessions];
      final stats = await _repository.getStats();

      emit(state.copyWith(
        sessions: sessions,
        stats: stats,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to save session: $e'));
    }
  }

  /// Sync a focus session to Insights for unified heatmap tracking.
  Future<void> _syncToInsights(FocusSession session) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Convert FocusType to SessionType
      final sessionType = SessionType.fromFocusType(session.type.dbValue);

      final userSession = UserSession(
        id: session.id,
        userId: userId,
        type: sessionType,
        durationMinutes: session.actualMinutes,
        actualDurationSeconds: session.actualDurationSeconds,
        sessionDate: session.sessionDate,
        completed: session.wasCompleted,
        prayerAnswered: false,
        createdAt: DateTime.now(),
      );

      await _insightsRepository.recordSession(userSession);
      KneelLogger.log(
        'Synced focus session to insights: ${session.id}',
        context: 'FocusCubit',
      );
    } catch (e) {
      // Don't fail the main save if insights sync fails
      KneelLogger.error('FocusCubit._syncToInsights', e);
    }
  }

  /// Reset timer state without saving.
  void _resetTimer() {
    emit(state.copyWith(
      isTimerRunning: false,
      isTimerPaused: false,
      clearActiveType: true,
      clearActivePrayerId: true,
      clearActivePrayerTitle: true,
      plannedDurationSeconds: 0,
      elapsedSeconds: 0,
      clearTimerStartedAt: true,
      isOpenEnded: false,
    ));
  }

  /// Cancel timer without saving (user backed out).
  void cancelTimer() {
    _timer?.cancel();
    _resetTimer();
  }

  /// Add extra time to running timer.
  void addTime(int minutes) {
    if (state.isTimerRunning) {
      emit(state.copyWith(
        plannedDurationSeconds: state.plannedDurationSeconds + (minutes * 60),
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
