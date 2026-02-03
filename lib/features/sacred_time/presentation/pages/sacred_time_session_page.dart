import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/insights/domain/entities/user_session.dart';
import 'package:quick_church/features/insights/presentation/bloc/insights_cubit.dart';
import 'package:quick_church/features/insights/presentation/widgets/streak_victory_overlay.dart';
import 'package:quick_church/features/sacred_time/domain/entities/sacred_time_session.dart';
import 'package:quick_church/features/sacred_time/presentation/widgets/breathing_gradient.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';

/// The immersive Sacred Time session page.
/// Features:
/// - Full-screen, distraction-free UI
/// - Hidden status/navigation bars
/// - Breathing mesh gradient background
/// - Minimalist countdown timer with circular progress
/// - iOS-style rich text canvas
/// - Double-tap to reveal exit
/// - Auto-save on completion
/// - Insights integration for streaks
/// - "Mark as Answered" toggle for prayers
class SacredTimeSessionPage extends StatefulWidget {
  final SacredTimeConfig config;
  final String? userId;

  const SacredTimeSessionPage({
    super.key,
    required this.config,
    this.userId,
  });

  @override
  State<SacredTimeSessionPage> createState() => _SacredTimeSessionPageState();
}

class _SacredTimeSessionPageState extends State<SacredTimeSessionPage>
    with TickerProviderStateMixin {
  // Timer state
  late int _remainingSeconds;
  late int _totalSeconds;
  Timer? _timer;
  bool _isCompleted = false;
  bool _isPaused = false;

  // Stopwatch mode (counts UP instead of DOWN)
  bool get _isStopwatch => widget.config.duration.isStopwatch;

  // UI state
  bool _showExitButton = false;
  bool _isVanished = false;
  Timer? _vanishTimer;
  bool _showStreakSummary = false;

  // Streak stats for completion summary
  StreakStats? _newStreakStats;

  // Text content
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  // Session tracking
  late DateTime _startTime;
  int _elapsedSeconds = 0;
  String? _savedNoteId;

  // Prayer persistence tracking
  int? _prayerTimesCount;

  @override
  void initState() {
    super.initState();
    // For stopwatch mode, we count UP from 0. For timer mode, we count DOWN.
    _totalSeconds = _isStopwatch ? 0 : widget.config.duration.minutes * 60;
    _remainingSeconds = _totalSeconds;
    _startTime = DateTime.now();

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Setup immersive mode
    _enterImmersiveMode();

    // Enable wakelock
    WakelockPlus.enable();

    // Start timer after entry animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _startTimer();
        _scheduleVanish();
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _vanishTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();

    // Disable wakelock
    WakelockPlus.disable();

    // Restore system UI
    _exitImmersiveMode();
    super.dispose();
  }

  void _enterImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _exitImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _elapsedSeconds++;
          if (_isStopwatch) {
            // Stopwatch mode: count UP, never auto-complete
            _remainingSeconds = _elapsedSeconds;
          } else {
            // Timer mode: count DOWN to completion
            if (_remainingSeconds > 0) {
              _remainingSeconds--;
            } else {
              _onTimerComplete();
            }
          }
        });
      }
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    setState(() => _isCompleted = true);

    // Success haptic pattern
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      HapticFeedback.lightImpact();
    });

    // Record session to Supabase and show streak summary
    _recordSessionAndShowStreak(completed: true);
  }

  Future<void> _recordSessionAndShowStreak({required bool completed}) async {
    int previousStreak = 0;
    int? prayerCount;
    try {
      final insightsCubit = context.read<InsightsCubit>();

      // Get previous streak before recording
      final currentStats = await insightsCubit.getStreakStats();
      previousStreak = currentStats.currentStreak;

      // Record the session
      // For stopwatch mode, duration is the elapsed time in minutes
      final durationMinutes = _isStopwatch
          ? (_elapsedSeconds / 60).ceil().clamp(1, 999)
          : widget.config.duration.minutes;

      // If this is a prayer session with a specific prayer, record to prayer_logs
      // This enables the "Prayed Xх" persistence badge on the prayer card
      if (widget.config.focusArea == SacredFocusArea.prayer &&
          widget.config.prayerId != null) {
        try {
          final prayerCubit = context.read<PrayerCubit>();
          prayerCount = await prayerCubit.recordPrayerSession(
            prayerId: widget.config.prayerId!,
            durationMinutes: durationMinutes,
            actualDurationSeconds: _elapsedSeconds,
          );
          if (mounted && prayerCount != null) {
            setState(() => _prayerTimesCount = prayerCount);
          }
        } catch (e) {
          // Silent fail - prayer tracking is not critical
        }
      }

      final stats = await insightsCubit.recordSession(
        type: SessionType.fromFocusName(widget.config.focusArea.name),
        durationMinutes: durationMinutes,
        actualDurationSeconds: _elapsedSeconds,
        completed: completed,
        noteId: _savedNoteId,
      );

      if (mounted && stats != null) {
        setState(() {
          _newStreakStats = stats;
        });

        // Show victory overlay if streak increased or is new
        if (completed && stats.currentStreak > 0) {
          final isNewStreak = previousStreak == 0 ||
              (stats.currentStreak == 1 && previousStreak > 1);
          final streakIncreased = stats.currentStreak > previousStreak;

          if (streakIncreased || isNewStreak) {
            // Show the animated victory overlay
            await StreakVictoryOverlay.show(
              context,
              newStreak: stats.currentStreak,
              previousStreak: previousStreak,
              isNewStreak: isNewStreak,
            );
          } else {
            // Just show the summary overlay for same-day sessions
            setState(() => _showStreakSummary = true);
          }
        }
      }
    } catch (e) {
      // Silent fail - insights are not critical
    }

    // Show completion UI
    if (mounted) {
      setState(() {
        _showExitButton = true;
        _isVanished = false;
      });
    }
  }

  void _scheduleVanish() {
    _vanishTimer?.cancel();
    _vanishTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isCompleted && !_textFocusNode.hasFocus) {
        setState(() => _isVanished = true);
      }
    });
  }

  void _cancelVanish() {
    _vanishTimer?.cancel();
    if (mounted) {
      setState(() => _isVanished = false);
      _scheduleVanish();
    }
  }

  void _onDoubleTap() {
    HapticFeedback.selectionClick();
    setState(() {
      _showExitButton = !_showExitButton;
      if (_showExitButton) {
        _isVanished = false;
      }
    });
  }

  Future<void> _saveAndExit({bool completed = true}) async {
    HapticFeedback.mediumImpact();

    final content = _textController.text.trim();

    // Save note if there's content
    if (content.isNotEmpty) {
      try {
        final sermonCubit = context.read<SermonCubit>();

        // Include session metadata in the content
        final sessionInfo = '--- Sacred Time Session ---\n'
            'Focus: ${widget.config.focusArea.label}\n'
            'Duration: ${widget.config.duration.label} (${_formatTime(_elapsedSeconds)} actual)\n'
            'Started: ${_formatDateTime(_startTime)}\n'
            '---\n\n$content';

        final noteId = const Uuid().v4();
        final note = SermonNote(
          id: noteId,
          userId: widget.userId ?? '',
          seriesId: null,
          title: '${widget.config.focusArea.label} - ${_formatDate(DateTime.now())}',
          preacher: 'Sacred Time',
          verse: null,
          content: sessionInfo,
          sermonDate: DateTime.now(),
          isPinned: false,
          tags: [
            'sacred-time',
            widget.config.focusArea.name,
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await sermonCubit.saveNote(note);
        _savedNoteId = noteId;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Session saved to Sermon Vault',
                style: GoogleFonts.inter(),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        // Silent fail
      }
    }

    // If exiting early (not completed), record the session now
    if (!_isCompleted && !completed) {
      await _recordSessionAndShowStreak(completed: false);
    }

    if (mounted) {
      Navigator.of(context).pop(completed);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    // For stopwatch mode, use a pulsing animation instead of progress
    final progress = _isStopwatch ? 0.0 : (1 - (_remainingSeconds / _totalSeconds));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation();
        }
      },
      child: GestureDetector(
        onDoubleTap: _onDoubleTap,
        onTap: _cancelVanish,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // Breathing gradient background
              Positioned.fill(
                child: BreathingGradient(
                  breathCycle: const Duration(seconds: 8),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Timer section
                    AnimatedOpacity(
                      opacity: _isVanished ? 0.3 : 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: _buildTimerSection(progress),
                    ),

                    // Text canvas
                    Expanded(
                      child: _buildTextCanvas(),
                    ),

                    // Note: "Mark as Answered" has been moved to the Prayer Vault
                    // Marking a prayer as answered is a spiritual transition that
                    // belongs in the management phase, not during the act of praying.
                    // See Luke 18:1 - "pray and not give up"

                    // Bottom section (exit button when visible)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _showExitButton ? 120 : 0,
                      child: AnimatedOpacity(
                        opacity: _showExitButton ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: _buildExitSection(),
                      ),
                    ),
                  ],
                ),
              ),

              // Streak Summary overlay (shown after completion)
              if (_showStreakSummary && _newStreakStats != null)
                _buildStreakSummaryOverlay(),

              // Completion overlay (shown after streak summary dismissed)
              if (_isCompleted && !_showStreakSummary)
                _buildCompletionOverlay(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildTimerSection(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Column(
        children: [
          // Focus area indicator
          AnimatedOpacity(
            opacity: _isVanished ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Text(
                widget.config.focusArea.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

          const SizedBox(height: 24),

          // Circular progress with timer
          Stack(
            alignment: Alignment.center,
            children: [
              // Background breathing circle
              BreathingCircle(
                size: 180,
                color: AppTheme.primaryColor,
                breathCycle: const Duration(seconds: 4),
              ),

              // Progress ring
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withAlpha(20),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isCompleted ? AppTheme.secondaryColor : Colors.white70,
                  ),
                ),
              ),

              // Timer text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isStopwatch
                        ? _formatTime(_elapsedSeconds)
                        : _formatTime(_remainingSeconds),
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  if (!_isCompleted)
                    Text(
                      _isStopwatch ? 'elapsed' : 'remaining',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white38,
                        letterSpacing: 2,
                      ),
                    ),
                ],
              ),
            ],
          ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 800.ms,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }

  Widget _buildTextCanvas() {
    return GestureDetector(
      onTap: () {
        _cancelVanish();
        _textFocusNode.requestFocus();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(40),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withAlpha(10),
          ),
        ),
        child: TextField(
          controller: _textController,
          focusNode: _textFocusNode,
          maxLines: null,
          expands: true,
          textAlign: TextAlign.left,
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white.withAlpha(230),
            height: 1.8,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            hintText: _getHintText(),
            hintStyle: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white.withAlpha(50),
              height: 1.8,
              fontStyle: FontStyle.italic,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          cursorColor: AppTheme.primaryColor,
          cursorWidth: 2,
          onTap: _cancelVanish,
          onChanged: (_) => _cancelVanish(),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms);
  }

  // Note: _buildAnsweredToggle has been removed.
  // "Mark as Answered" belongs in the Prayer Vault, not during the sacred act of praying.
  // This respects the spiritual journey where persistence is the focus (Luke 18:1).

  String _getHintText() {
    switch (widget.config.focusArea) {
      case SacredFocusArea.prayer:
        return 'Pour out your heart to God...';
      case SacredFocusArea.bibleStudy:
        return 'Capture your insights from Scripture...';
      case SacredFocusArea.meditation:
        return 'What is the Spirit revealing to you...';
      case SacredFocusArea.sermonPrep:
        return 'Let your message take shape...';
    }
  }

  Widget _buildExitSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
      child: Row(
        children: [
          if (!_isCompleted && !_isStopwatch)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showExitConfirmation(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withAlpha(40)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(LucideIcons.doorOpen, size: 18),
                label: Text(
                  'Leave Early',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          // Stopwatch mode: show Finish button to manually complete
          if (!_isCompleted && _isStopwatch)
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  setState(() => _isCompleted = true);
                  _timer?.cancel();
                  HapticFeedback.heavyImpact();
                  _recordSessionAndShowStreak(completed: true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(LucideIcons.check, size: 20),
                label: Text(
                  'Finish Session',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_isCompleted)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _saveAndExit(completed: true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(LucideIcons.check, size: 20),
                label: Text(
                  'Complete Session',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakSummaryOverlay() {
    final stats = _newStreakStats!;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _showStreakSummary = false);
      },
      child: Container(
        color: Colors.black.withAlpha(200),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withAlpha(60),
                  AppTheme.goldenPromise.withAlpha(40),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppTheme.goldenPromise.withAlpha(60),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fire icon for streak
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.goldenPromise.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stats.currentStreak >= 7 ? LucideIcons.flame : LucideIcons.sparkles,
                    size: 48,
                    color: AppTheme.goldenPromise,
                  ),
                ),
                const SizedBox(height: 24),

                // Streak number
                Text(
                  'Day ${stats.currentStreak}!',
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldenPromise,
                  ),
                ),
                const SizedBox(height: 8),

                // Motivational message
                Text(
                  stats.motivationalMessage,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Prayer persistence message (Luke 18:1 - "pray and not give up")
                if (_prayerTimesCount != null && widget.config.prayerTitle != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.flame,
                          size: 18,
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "You've lifted up \"${widget.config.prayerTitle}\" $_prayerTimesCount times",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      icon: LucideIcons.trophy,
                      value: stats.longestStreak.toString(),
                      label: 'Best',
                    ),
                    _buildStatItem(
                      icon: LucideIcons.clock,
                      value: '${stats.totalMinutes}m',
                      label: 'Total',
                    ),
                    if (stats.answeredPrayers > 0)
                      _buildStatItem(
                        icon: LucideIcons.heart,
                        value: stats.answeredPrayers.toString(),
                        label: 'Answered',
                      ),
                  ],
                ),
                const SizedBox(height: 28),

                // Continue button
                Text(
                  'Tap anywhere to continue',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(
            begin: const Offset(0.9, 0.9),
            curve: Curves.easeOut,
          ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.white54),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionOverlay() {
    return Container(
      color: Colors.black.withAlpha(150),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.secondaryColor.withAlpha(60),
                  width: 2,
                ),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 48,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Session Complete',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isStopwatch
                  ? 'You spent ${_formatTime(_elapsedSeconds)} in the sanctuary'
                  : 'You spent ${widget.config.duration.label} in the sanctuary',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _saveAndExit(completed: true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(LucideIcons.save, size: 20),
              label: Text(
                'Save & Exit',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  void _showExitConfirmation() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Leave Sanctuary?',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          _isStopwatch
              ? 'You have been in the sanctuary for ${_formatTime(_elapsedSeconds)}. '
                'Your notes will be saved.'
              : 'You still have ${_formatTime(_remainingSeconds)} remaining. '
                'Your notes will be saved.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Stay',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveAndExit(completed: false);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(20),
            ),
            child: Text(
              'Leave',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
