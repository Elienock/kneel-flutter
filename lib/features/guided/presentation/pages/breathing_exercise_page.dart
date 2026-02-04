import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/guided/domain/entities/guided_session.dart';

/// Visual breathing exercise page with animated guide.
class BreathingExercisePage extends StatefulWidget {
  final GuidedPlan plan;
  final BreathingContent content;

  const BreathingExercisePage({
    super.key,
    required this.plan,
    required this.content,
  });

  @override
  State<BreathingExercisePage> createState() => _BreathingExercisePageState();
}

class _BreathingExercisePageState extends State<BreathingExercisePage>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isRunning = false;
  bool _isCompleted = false;
  int _currentCycle = 0;
  BreathPhase _currentPhase = BreathPhase.idle;
  Timer? _phaseTimer;
  int _phaseSecondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    final totalCycleTime = widget.content.inhaleSeconds +
        widget.content.holdSeconds +
        widget.content.exhaleSeconds;

    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalCycleTime),
    );

    // Scale: expand during inhale, stay during hold, contract during exhale
    final inhaleRatio = widget.content.inhaleSeconds / totalCycleTime;
    final holdRatio = widget.content.holdSeconds / totalCycleTime;

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: inhaleRatio * 100,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: holdRatio * 100,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.6).chain(CurveTween(curve: Curves.easeInOut)),
        weight: (1 - inhaleRatio - holdRatio) * 100,
      ),
    ]).animate(_breathController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.0),
        weight: inhaleRatio * 100,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: holdRatio * 100,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.4),
        weight: (1 - inhaleRatio - holdRatio) * 100,
      ),
    ]).animate(_breathController);

    _breathController.addStatusListener(_onAnimationStatus);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isRunning) {
      _currentCycle++;
      if (_currentCycle < widget.content.cycles) {
        _breathController.reset();
        _startCycle();
      } else {
        _completeExercise();
      }
    }
  }

  void _startExercise() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = true;
      _currentCycle = 0;
      _isCompleted = false;
    });
    _startCycle();
  }

  void _startCycle() {
    _breathController.forward(from: 0);
    _startPhase(BreathPhase.inhale);
  }

  void _startPhase(BreathPhase phase) {
    setState(() {
      _currentPhase = phase;
      _phaseSecondsRemaining = _getPhaseDuration(phase);
    });

    _phaseTimer?.cancel();
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_phaseSecondsRemaining > 1) {
        setState(() => _phaseSecondsRemaining--);
      } else {
        timer.cancel();
        _advancePhase();
      }
    });
  }

  void _advancePhase() {
    if (!_isRunning) return;

    switch (_currentPhase) {
      case BreathPhase.inhale:
        if (widget.content.holdSeconds > 0) {
          _startPhase(BreathPhase.hold);
        } else {
          _startPhase(BreathPhase.exhale);
        }
        break;
      case BreathPhase.hold:
        _startPhase(BreathPhase.exhale);
        break;
      case BreathPhase.exhale:
      case BreathPhase.idle:
        // Cycle completion handled by animation listener
        break;
    }
  }

  int _getPhaseDuration(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale:
        return widget.content.inhaleSeconds;
      case BreathPhase.hold:
        return widget.content.holdSeconds;
      case BreathPhase.exhale:
        return widget.content.exhaleSeconds;
      case BreathPhase.idle:
        return 0;
    }
  }

  void _pauseExercise() {
    HapticFeedback.lightImpact();
    _phaseTimer?.cancel();
    _breathController.stop();
    setState(() => _isRunning = false);
  }

  void _completeExercise() {
    HapticFeedback.heavyImpact();
    _phaseTimer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
      _currentPhase = BreathPhase.idle;
    });
  }

  void _resetExercise() {
    HapticFeedback.lightImpact();
    _phaseTimer?.cancel();
    _breathController.reset();
    setState(() {
      _isRunning = false;
      _isCompleted = false;
      _currentCycle = 0;
      _currentPhase = BreathPhase.idle;
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final content = widget.content;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: widget.plan.gradientStart,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [widget.plan.gradientStart, widget.plan.gradientEnd],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Breathing Exercise',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Introduction text
                  Text(
                    content.introduction,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white.withAlpha(200) : Colors.black87,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Scripture verse if present
                  if (content.scripture != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.plan.gradientStart.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.plan.gradientStart.withAlpha(50),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.bookOpen,
                            size: 18,
                            color: widget.plan.gradientStart,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              content.scripture!,
                              style: GoogleFonts.literata(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white.withAlpha(200) : Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Breathing visual
                  _buildBreathingVisual(isDark),
                  const SizedBox(height: 24),

                  // Phase indicator
                  _buildPhaseIndicator(isDark),
                  const SizedBox(height: 16),

                  // Progress indicator
                  _buildProgressIndicator(isDark),
                  const SizedBox(height: 32),

                  // Controls
                  _buildControls(isDark),

                  // Completion state
                  if (_isCompleted) ...[
                    const SizedBox(height: 32),
                    _buildCompletionState(isDark),
                  ],

                  // Closing reflection
                  if (content.closingReflection != null && _isCompleted) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.plan.gradientStart.withAlpha(15),
                            widget.plan.gradientEnd.withAlpha(10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.plan.gradientStart.withAlpha(50),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.sparkles,
                                size: 18,
                                color: widget.plan.gradientStart,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reflection',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: widget.plan.gradientStart,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            content.closingReflection!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: isDark ? Colors.white.withAlpha(200) : Colors.black87,
                              height: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom action bar
      bottomNavigationBar: _isCompleted
          ? Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exercise completed! Great job!'),
                      backgroundColor: AppTheme.answeredColor,
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(LucideIcons.check),
                label: const Text('Complete'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.answeredColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBreathingVisual(bool isDark) {
    return SizedBox(
      height: 240,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow rings
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _breathController,
              builder: (context, child) {
                final scale = _scaleAnimation.value * (1 + index * 0.15);
                final opacity = (_opacityAnimation.value * 0.3) / (index + 1);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.plan.gradientStart.withAlpha((opacity * 255).toInt()),
                    ),
                  ),
                );
              },
            );
          }),
          // Main breathing circle
          AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.plan.gradientStart,
                        widget.plan.gradientEnd,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.plan.gradientStart.withAlpha(
                          (_opacityAnimation.value * 150).toInt(),
                        ),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isRunning || _isCompleted
                        ? Text(
                            _isCompleted
                                ? 'Done'
                                : _phaseSecondsRemaining.toString(),
                            style: GoogleFonts.outfit(
                              fontSize: _isCompleted ? 24 : 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            LucideIcons.wind,
                            size: 48,
                            color: Colors.white.withAlpha(200),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(bool isDark) {
    String phaseText;
    IconData phaseIcon;

    switch (_currentPhase) {
      case BreathPhase.inhale:
        phaseText = 'Breathe In';
        phaseIcon = LucideIcons.arrowUp;
        break;
      case BreathPhase.hold:
        phaseText = 'Hold';
        phaseIcon = LucideIcons.pause;
        break;
      case BreathPhase.exhale:
        phaseText = 'Breathe Out';
        phaseIcon = LucideIcons.arrowDown;
        break;
      case BreathPhase.idle:
        phaseText = _isCompleted ? 'Complete' : 'Ready';
        phaseIcon = _isCompleted ? LucideIcons.check : LucideIcons.play;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_currentPhase),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: widget.plan.gradientStart.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              phaseIcon,
              size: 20,
              color: widget.plan.gradientStart,
            ),
            const SizedBox(width: 8),
            Text(
              phaseText,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.plan.gradientStart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Column(
      children: [
        Text(
          'Cycle ${_currentCycle + 1} of ${widget.content.cycles}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _isCompleted
                  ? 1.0
                  : (_currentCycle / widget.content.cycles),
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation(widget.plan.gradientStart),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.content.totalMinutes} min total',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(bool isDark) {
    if (_isCompleted) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isRunning || _currentCycle > 0) ...[
          // Reset button
          OutlinedButton.icon(
            onPressed: _resetExercise,
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: const Text('Reset'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.black54,
              side: BorderSide(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(width: 16),
        ],
        // Start/Pause button
        FilledButton.icon(
          onPressed: _isRunning ? _pauseExercise : _startExercise,
          icon: Icon(_isRunning ? LucideIcons.pause : LucideIcons.play, size: 20),
          label: Text(_isRunning ? 'Pause' : (_currentCycle > 0 ? 'Resume' : 'Start')),
          style: FilledButton.styleFrom(
            backgroundColor: widget.plan.gradientStart,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionState(bool isDark) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.answeredColor.withAlpha(25),
          ),
          child: const Center(
            child: Icon(
              LucideIcons.checkCircle,
              size: 40,
              color: AppTheme.answeredColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Well Done!',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You completed ${widget.content.cycles} breathing cycles',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

enum BreathPhase { idle, inhale, hold, exhale }
