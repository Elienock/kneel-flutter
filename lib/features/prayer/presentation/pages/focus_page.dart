import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'package:quick_church/features/prayer/presentation/bloc/session_cubit.dart';

/// Focus tab - distraction-free prayer mode with Sacred Timer.
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isInFocusMode = false;
  int _selectedDuration = 5; // Default 5 minutes
  int _prayersPrayed = 0;
  DateTime? _sessionStartTime;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startFocusMode(int durationMinutes) {
    setState(() {
      _selectedDuration = durationMinutes;
      _isInFocusMode = true;
      _prayersPrayed = 0;
      _sessionStartTime = DateTime.now();
    });
  }

  void _onSessionComplete(int actualDurationSeconds) {
    final endTime = DateTime.now();
    context.read<SessionCubit>().recordSession(
          durationSeconds: actualDurationSeconds,
          startedAt: _sessionStartTime!,
          endedAt: endTime,
          prayersPrayed: _prayersPrayed,
        );
    setState(() {
      _isInFocusMode = false;
      _sessionStartTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<PrayerCubit, PrayerState>(
      builder: (context, state) {
        final prayers = state is PrayerLoaded ? state.prayers : <Prayer>[];
        final activePrayers =
            prayers.where((p) => p.status == PrayerStatus.active).toList();

        if (_isInFocusMode) {
          return _FocusModeView(
            prayers: activePrayers,
            currentIndex: _currentIndex,
            pageController: _pageController,
            selectedDuration: _selectedDuration,
            onExit: () => setState(() => _isInFocusMode = false),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            onPrayed: () => setState(() => _prayersPrayed++),
            onSessionComplete: _onSessionComplete,
          );
        }

        return Scaffold(
          backgroundColor:
              isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor:
                      isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                  title: Text(
                    'Focus',
                    style: theme.textTheme.displayMedium,
                  ),
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Focus Mode Card with Duration Selection
                      _FocusModeIntroCard(
                        prayerCount: activePrayers.length,
                        onStartFocus: activePrayers.isNotEmpty
                            ? _startFocusMode
                            : null,
                      ),
                      const SizedBox(height: 24),

                      // Quick Prayer List Preview
                      if (activePrayers.isNotEmpty) ...[
                        Text(
                          'Prayer Queue',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        ...activePrayers.take(5).map((prayer) => _PrayerQueueItem(
                              prayer: prayer,
                              isFirst: activePrayers.indexOf(prayer) == 0,
                            )),
                        if (activePrayers.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '+${activePrayers.length - 5} more prayers',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ] else
                        _EmptyFocusState(),

                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Focus mode intro card with duration selection.
class _FocusModeIntroCard extends StatefulWidget {
  final int prayerCount;
  final void Function(int duration)? onStartFocus;

  const _FocusModeIntroCard({
    required this.prayerCount,
    this.onStartFocus,
  });

  @override
  State<_FocusModeIntroCard> createState() => _FocusModeIntroCardState();
}

class _FocusModeIntroCardState extends State<_FocusModeIntroCard> {
  int _selectedDuration = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
              : [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.timer,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.prayerCount} prayers',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Sacred Timer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How long would you like to dwell in prayer?',
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Duration Selection
          Text(
            'Select Duration',
            style: GoogleFonts.inter(
              color: Colors.white.withAlpha(153),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [5, 10, 20].map((minutes) {
              final isSelected = _selectedDuration == minutes;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDuration = minutes),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: minutes != 20 ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withAlpha(51),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$minutes',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'min',
                          style: GoogleFonts.inter(
                            color: Colors.white.withAlpha(179),
                            fontSize: 12,
                          ),
                        ),
                        if (minutes >= 10)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(51),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Deep',
                              style: GoogleFonts.inter(
                                color: Colors.amber,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onStartFocus != null
                  ? () => widget.onStartFocus!(_selectedDuration)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C1C1E),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(LucideIcons.play),
              label: const Text('Begin Prayer Time'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prayer queue item.
class _PrayerQueueItem extends StatelessWidget {
  final Prayer prayer;
  final bool isFirst;

  const _PrayerQueueItem({
    required this.prayer,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final priorityColor = switch (prayer.priority) {
      PrayerPriority.urgent => AppTheme.urgentColor,
      PrayerPriority.high => AppTheme.highColor,
      PrayerPriority.medium => AppTheme.mediumColor,
      PrayerPriority.low => AppTheme.lowColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: isFirst
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirst)
                  Text(
                    'UP NEXT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                Text(
                  prayer.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isFirst)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.play,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

/// Empty state for focus mode.
class _EmptyFocusState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            LucideIcons.crosshair,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Prayers',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add prayers to enter focus mode',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Full-screen focus mode view with timer.
class _FocusModeView extends StatefulWidget {
  final List<Prayer> prayers;
  final int currentIndex;
  final PageController pageController;
  final int selectedDuration;
  final VoidCallback onExit;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPrayed;
  final void Function(int actualDurationSeconds) onSessionComplete;

  const _FocusModeView({
    required this.prayers,
    required this.currentIndex,
    required this.pageController,
    required this.selectedDuration,
    required this.onExit,
    required this.onPageChanged,
    required this.onPrayed,
    required this.onSessionComplete,
  });

  @override
  State<_FocusModeView> createState() => _FocusModeViewState();
}

class _FocusModeViewState extends State<_FocusModeView>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late int _remainingSeconds;
  late int _totalSeconds;
  bool _isFinished = false;
  bool _isPaused = false;
  late AnimationController _pulseController;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.selectedDuration * 60;
    _remainingSeconds = _totalSeconds;
    _startTime = DateTime.now();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _startTimer();

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _onTimerComplete();
          }
        });
      }
    });
  }

  void _onTimerComplete() {
    _timer.cancel();
    setState(() {
      _isFinished = true;
    });
    HapticFeedback.heavyImpact();
    _pulseController.repeat(reverse: true);
  }

  void _finishSession() {
    final actualDuration = DateTime.now().difference(_startTime).inSeconds;
    widget.onSessionComplete(actualDuration);
    _exitFocusMode();
  }

  void _keepGoing() {
    setState(() {
      _isFinished = false;
      _remainingSeconds = 60; // Add 1 more minute
      _totalSeconds += 60;
    });
    _pulseController.stop();
    _pulseController.reset();
    _startTimer();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      HapticFeedback.lightImpact();
    }
  }

  void _exitFocusMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    widget.onExit();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = 1 - (_remainingSeconds / _totalSeconds);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFFAFAFA),
        body: Stack(
          children: [
            // Prayer cards
            PageView.builder(
              controller: widget.pageController,
              itemCount: widget.prayers.length,
              onPageChanged: widget.onPageChanged,
              itemBuilder: (context, index) {
                final prayer = widget.prayers[index];
                return _FocusPrayerCard(
                  prayer: prayer,
                  index: index,
                  total: widget.prayers.length,
                  progress: progress,
                  remainingTime: _formatTime(_remainingSeconds),
                  isFinished: _isFinished,
                  isPaused: _isPaused,
                  pulseAnimation: _pulseController,
                );
              },
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _showExitConfirmation,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withAlpha(26)
                                : Colors.black.withAlpha(13),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.x,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(26)
                              : Colors.black.withAlpha(13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.currentIndex + 1} of ${widget.prayers.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _togglePause,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withAlpha(26)
                                : Colors.black.withAlpha(13),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPaused ? LucideIcons.play : LucideIcons.pause,
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _isFinished
                      ? _buildFinishedActions(context)
                      : _buildActiveActions(context),
                ),
              ),
            ),

            // Page indicators
            Positioned(
              bottom: _isFinished ? 160 : 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.prayers.length > 10 ? 10 : widget.prayers.length,
                  (index) {
                    final adjustedIndex = widget.prayers.length > 10
                        ? (widget.currentIndex ~/ (widget.prayers.length / 10))
                            .clamp(0, 9)
                        : index;
                    final isActive = widget.prayers.length > 10
                        ? adjustedIndex == index
                        : widget.currentIndex == index;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primaryColor
                            : (isDark
                                ? Colors.white.withAlpha(51)
                                : Colors.black.withAlpha(26)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mark as prayed button
        _ActionButton(
          icon: LucideIcons.heart,
          label: 'Prayed',
          color: const Color(0xFFFF6B6B),
          onTap: () {
            context.read<PrayerCubit>().incrementPrayerCount(
                  widget.prayers[widget.currentIndex].id,
                );
            widget.onPrayed();
            HapticFeedback.mediumImpact();
          },
        ),
        const SizedBox(width: 16),
        // Mark as answered button
        _ActionButton(
          icon: LucideIcons.sparkles,
          label: 'Answered',
          color: AppTheme.answeredColor,
          onTap: () {
            context.read<PrayerCubit>().markAsAnswered(
                  widget.prayers[widget.currentIndex].id,
                );
            HapticFeedback.heavyImpact();
            // Move to next prayer
            if (widget.currentIndex < widget.prayers.length - 1) {
              widget.pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildFinishedActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Session Complete',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _keepGoing,
                icon: const Icon(LucideIcons.plus),
                label: const Text('Keep Going'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _finishSession,
                icon: const Icon(LucideIcons.check),
                label: const Text('Finish'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showExitConfirmation() {
    final actualDuration = DateTime.now().difference(_startTime).inSeconds;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'End Prayer Time?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          actualDuration >= 60
              ? 'You\'ve prayed for ${actualDuration ~/ 60} minutes. Do you want to save this session?'
              : 'You\'ve only prayed for a few seconds. Exit without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          if (actualDuration >= 60)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSessionComplete(actualDuration);
                _exitFocusMode();
              },
              child: const Text('Save & Exit'),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exitFocusMode();
              },
              child: const Text('Exit'),
            ),
        ],
      ),
    );
  }
}

/// Focus prayer card with circular timer progress.
class _FocusPrayerCard extends StatelessWidget {
  final Prayer prayer;
  final int index;
  final int total;
  final double progress;
  final String remainingTime;
  final bool isFinished;
  final bool isPaused;
  final AnimationController pulseAnimation;

  const _FocusPrayerCard({
    required this.prayer,
    required this.index,
    required this.total,
    required this.progress,
    required this.remainingTime,
    required this.isFinished,
    required this.isPaused,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Timer
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                final scale = isFinished
                    ? 1.0 + (pulseAnimation.value * 0.05)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 8,
                            backgroundColor: isDark
                                ? Colors.white.withAlpha(26)
                                : Colors.black.withAlpha(13),
                            color: Colors.transparent,
                          ),
                        ),
                        // Progress circle
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: Colors.transparent,
                            color: isFinished
                                ? AppTheme.answeredColor
                                : AppTheme.primaryColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // Time display
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPaused)
                              Icon(
                                LucideIcons.pause,
                                color: AppTheme.primaryColor,
                                size: 24,
                              )
                            else if (isFinished)
                              Icon(
                                LucideIcons.check,
                                color: AppTheme.answeredColor,
                                size: 32,
                              )
                            else
                              Text(
                                remainingTime,
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark ? Colors.white : const Color(0xFF1C1C1E),
                                ),
                              ),
                            if (!isFinished && !isPaused)
                              Text(
                                'remaining',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white.withAlpha(153)
                                      : const Color(0xFF8E8E93),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Priority badge
            if (prayer.priority == PrayerPriority.urgent)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.urgentColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 16,
                      color: AppTheme.urgentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'URGENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.urgentColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

            // Prayer title
            Text(
              prayer.title,
              style: theme.textTheme.displayMedium?.copyWith(
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Prayer description
            Text(
              prayer.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: isDark
                    ? Colors.white.withAlpha(179)
                    : const Color(0xFF636366),
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),

            // Prayer count
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.heart,
                  size: 18,
                  color: const Color(0xFFFF6B6B).withAlpha(128),
                ),
                const SizedBox(width: 6),
                Text(
                  'Prayed ${prayer.prayerCount} times',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Action button for focus mode.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withAlpha(77),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
