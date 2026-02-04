import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/focus/domain/entities/focus_session.dart';
import 'package:quick_church/features/focus/presentation/bloc/focus_cubit.dart';
import 'package:quick_church/features/focus/presentation/bloc/focus_state.dart';

/// Immersive focus timer screen.
///
/// Can be launched in two modes:
/// 1. From FocusPage - timer already started via FocusCubit.startTimer()
/// 2. Direct launch - provide [durationMinutes] to auto-start
class FocusTimerPage extends StatefulWidget {
  /// The type of focus activity.
  final FocusType type;

  /// Optional prayer title for specific prayer type.
  final String? prayerTitle;

  /// Duration in minutes - if provided, auto-starts the timer.
  final int? durationMinutes;

  /// If true, this is a quick pray session from home FAB.
  final bool isQuickPray;

  const FocusTimerPage({
    super.key,
    this.type = FocusType.generalPrayer,
    this.prayerTitle,
    this.durationMinutes,
    this.isQuickPray = false,
  });

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showCompletion = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Keep screen awake during focus
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Auto-start timer if duration is provided (direct launch mode)
    if (widget.durationMinutes != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FocusCubit>().startTimer(
          type: widget.type,
          durationMinutes: widget.durationMinutes!,
          prayerTitle: widget.prayerTitle,
        );
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Color _getTypeColor() {
    switch (widget.type) {
      case FocusType.bibleStudy:
        return const Color(0xFF6366F1);
      case FocusType.meditation:
        return const Color(0xFF14B8A6);
      case FocusType.generalPrayer:
        return AppTheme.primaryColor;
      case FocusType.specificPrayer:
        return const Color(0xFFEC4899);
      case FocusType.worship:
        return const Color(0xFFF59E0B);
      case FocusType.journaling:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case FocusType.bibleStudy:
        return LucideIcons.bookOpen;
      case FocusType.meditation:
        return LucideIcons.brain;
      case FocusType.generalPrayer:
        return LucideIcons.handMetal;
      case FocusType.specificPrayer:
        return LucideIcons.heartHandshake;
      case FocusType.worship:
        return LucideIcons.music;
      case FocusType.journaling:
        return LucideIcons.pencil;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor();

    return BlocConsumer<FocusCubit, FocusState>(
      listener: (context, state) {
        if (state.isTimerComplete && !_showCompletion) {
          HapticFeedback.heavyImpact();
          setState(() => _showCompletion = true);
        }
      },
      builder: (context, state) {
        if (_showCompletion) {
          return _CompletionScreen(
            type: widget.type,
            prayerTitle: widget.prayerTitle,
            elapsedMinutes: state.elapsedSeconds ~/ 60,
            color: color,
            isOpenEnded: state.isOpenEnded,
            onDone: () {
              context.read<FocusCubit>().completeSession();
              Navigator.pop(context);
            },
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1C1C1E),
          body: SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white54),
                        onPressed: () => _showExitConfirmation(context),
                      ),
                      // Activity badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getTypeIcon(), color: color, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              widget.type.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Add time button
                      IconButton(
                        icon: const Icon(LucideIcons.plus, color: Colors.white54),
                        onPressed: () => _showAddTimeSheet(context),
                      ),
                    ],
                  ),
                ),

                // Prayer title if specific prayer
                if (widget.prayerTitle != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '"${widget.prayerTitle}"',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Timer display
                Expanded(
                  child: Center(
                    child: _buildTimerWidget(state, color),
                  ),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: _buildControls(context, state, color),
                ),

                // Motivational text
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    _getMotivationalText(state),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerWidget(FocusState state, Color color) {
    // For open-ended mode, show elapsed time counting up
    final displayTime = state.isOpenEnded
        ? state.elapsedTimeDisplay
        : state.remainingTimeDisplay;
    final displayLabel = state.isTimerPaused
        ? 'PAUSED'
        : (state.isOpenEnded ? 'ELAPSED' : 'REMAINING');

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: state.isTimerPaused ? 1.0 : _pulseAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow rings
              ...List.generate(3, (index) {
                return Container(
                  width: 260 + (index * 30),
                  height: 260 + (index * 30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withAlpha(30 - (index * 10)),
                      width: 2,
                    ),
                  ),
                );
              }),
              // Progress ring (for timed sessions)
              if (!state.isOpenEnded)
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: _TimerProgressPainter(
                      progress: state.progress,
                      color: color,
                      backgroundColor: Colors.white.withAlpha(20),
                    ),
                  ),
                ),
              // Pulsing ring for open-ended mode
              if (state.isOpenEnded)
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withAlpha(80),
                        width: 8,
                      ),
                    ),
                  ),
                ),
              // Timer text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayTime,
                    style: GoogleFonts.outfit(
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: state.isTimerPaused ? Colors.amber : Colors.white38,
                      letterSpacing: 2,
                    ),
                  ),
                  // Show current achievement level (subtle, no distraction)
                  if (state.isOpenEnded && state.currentAchievement != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state.currentAchievement!.title,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, FocusState state, Color color) {
    // For open-ended sessions, show Finish as the main action
    if (state.isOpenEnded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main action row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancel button
              _ControlButton(
                icon: LucideIcons.x,
                label: 'Cancel',
                color: Colors.white38,
                onTap: () => _showExitConfirmation(context),
              ),
              const SizedBox(width: 32),
              // Play/Pause button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (state.isTimerPaused) {
                    context.read<FocusCubit>().resumeTimer();
                  } else {
                    context.read<FocusCubit>().pauseTimer();
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(100),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    state.isTimerPaused ? LucideIcons.play : LucideIcons.pause,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              // Finish button for open-ended
              _ControlButton(
                icon: LucideIcons.check,
                label: 'Finish',
                color: AppTheme.answeredColor,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  setState(() => _showCompletion = true);
                },
              ),
            ],
          ),
        ],
      );
    }

    // Timed session controls
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // End early button
        _ControlButton(
          icon: LucideIcons.square,
          label: 'End',
          color: Colors.white38,
          onTap: () => _showEndEarlyConfirmation(context),
        ),
        const SizedBox(width: 32),
        // Play/Pause button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (state.isTimerPaused) {
              context.read<FocusCubit>().resumeTimer();
            } else {
              context.read<FocusCubit>().pauseTimer();
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(100),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              state.isTimerPaused ? LucideIcons.play : LucideIcons.pause,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 32),
        // Add 5 minutes
        _ControlButton(
          icon: LucideIcons.plus,
          label: '+5 min',
          color: Colors.white38,
          onTap: () {
            HapticFeedback.lightImpact();
            context.read<FocusCubit>().addTime(5);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Added 5 minutes'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getMotivationalText(FocusState state) {
    if (state.isTimerPaused) {
      return 'Take your time. Resume when ready.';
    }

    // Open-ended mode messages based on elapsed time
    if (state.isOpenEnded) {
      final minutes = state.elapsedMinutes;
      if (minutes < 5) {
        return 'Settle your mind and be present.';
      } else if (minutes < 10) {
        return 'You\'re building a beautiful habit.';
      } else if (minutes < 20) {
        return 'Deep in the zone. Keep going!';
      } else if (minutes < 30) {
        return 'Impressive dedication. You\'re doing great!';
      } else if (minutes < 45) {
        return 'Half hour strong. What a blessing!';
      } else if (minutes < 60) {
        return 'Almost an hour. You\'re inspiring!';
      } else {
        return 'An hour of focus. Truly remarkable!';
      }
    }

    // Timed mode messages based on progress
    final progress = state.progress;
    if (progress < 0.25) {
      return 'Settle your mind and be present.';
    } else if (progress < 0.5) {
      return 'You\'re doing great. Stay focused.';
    } else if (progress < 0.75) {
      return 'More than halfway there!';
    } else {
      return 'Almost there. Finish strong!';
    }
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(
          'Exit Session?',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Text(
          'Your progress will not be saved.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FocusCubit>().cancelTimer();
              Navigator.pop(context);
            },
            child: Text(
              'Exit',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showEndEarlyConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(
          'End Early?',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        content: Text(
          'Your progress so far will be saved.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<FocusCubit>().endTimerEarly();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'End Session',
              style: GoogleFonts.inter(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTimeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Time',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AddTimeOption(
                    minutes: 5,
                    onTap: () {
                      context.read<FocusCubit>().addTime(5);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AddTimeOption(
                    minutes: 10,
                    onTap: () {
                      context.read<FocusCubit>().addTime(10);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AddTimeOption(
                    minutes: 15,
                    onTap: () {
                      context.read<FocusCubit>().addTime(15);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Control button widget.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Add time option button.
class _AddTimeOption extends StatelessWidget {
  final int minutes;
  final VoidCallback onTap;

  const _AddTimeOption({
    required this.minutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '+$minutes min',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Completion screen shown when timer finishes.
class _CompletionScreen extends StatelessWidget {
  final FocusType type;
  final String? prayerTitle;
  final int elapsedMinutes;
  final Color color;
  final VoidCallback onDone;
  final bool isOpenEnded;

  const _CompletionScreen({
    required this.type,
    this.prayerTitle,
    required this.elapsedMinutes,
    required this.color,
    required this.onDone,
    this.isOpenEnded = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get achievements earned in this session
    final achievements = FocusAchievement.getAchievementsFor(elapsedMinutes);
    final highestAchievement = achievements.isNotEmpty ? achievements.last : null;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Success animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.answeredColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.checkCircle,
                    color: AppTheme.answeredColor,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Well Done!',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You completed $elapsedMinutes minute${elapsedMinutes == 1 ? '' : 's'} of ${type.displayName.toLowerCase()}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),

              // Achievement card (if any milestone reached)
              if (highestAchievement != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF59E0B).withAlpha(40),
                        const Color(0xFFEF4444).withAlpha(30),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withAlpha(60),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        LucideIcons.trophy,
                        color: Color(0xFFF59E0B),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        highestAchievement.title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        highestAchievement.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              // Prayer card (if specific prayer)
              if (type == FocusType.specificPrayer && prayerTitle != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.heartHandshake, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prayed for',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            Text(
                              '"$prayerTitle"',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+1',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Stats summary
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: LucideIcons.clock,
                      value: '$elapsedMinutes',
                      label: 'Minutes',
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withAlpha(20),
                    ),
                    _StatItem(
                      icon: LucideIcons.target,
                      value: isOpenEnded ? 'Open' : 'Timed',
                      label: 'Session',
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withAlpha(20),
                    ),
                    _StatItem(
                      icon: LucideIcons.trophy,
                      value: '${achievements.length}',
                      label: 'Milestones',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              // Done button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small stat item for completion screen.
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
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
}

/// Custom painter for the timer progress ring.
class _TimerProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _TimerProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
