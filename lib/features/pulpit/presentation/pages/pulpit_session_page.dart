import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/pulpit/domain/entities/pulpit_prayer_group.dart';
import 'package:quick_church/features/pulpit/presentation/bloc/pulpit_cubit.dart';
import 'package:quick_church/features/pulpit/presentation/bloc/pulpit_state.dart';

/// Full-screen pulpit session display.
class PulpitSessionPage extends StatefulWidget {
  final PulpitPrayerGroup group;

  const PulpitSessionPage({super.key, required this.group});

  @override
  State<PulpitSessionPage> createState() => _PulpitSessionPageState();
}

class _PulpitSessionPageState extends State<PulpitSessionPage>
    with TickerProviderStateMixin {
  late PulpitSessionState _sessionState;
  Timer? _timer;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _sessionState = PulpitSessionState(group: widget.group);

    // Keep screen awake
    WakelockPlus.enable();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Progress animation for auto-advance timer
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.group.secondsPerPoint),
    );

    // Pulse animation for current point indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Start timer
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionState.isPaused) return;

      setState(() {
        _sessionState = _sessionState.copyWith(
          elapsedSeconds: _sessionState.elapsedSeconds + 1,
        );
      });

      // Auto-advance if enabled and time is up
      if (widget.group.autoAdvance &&
          _sessionState.elapsedSeconds >= widget.group.secondsPerPoint) {
        _nextPoint();
      }
    });

    // Start progress animation for auto-advance
    if (widget.group.autoAdvance) {
      _progressController.forward();
    }
  }

  void _togglePause() {
    HapticFeedback.mediumImpact();
    setState(() {
      _sessionState = _sessionState.copyWith(isPaused: !_sessionState.isPaused);
    });

    if (_sessionState.isPaused) {
      _progressController.stop();
    } else if (widget.group.autoAdvance) {
      _progressController.forward();
    }
  }

  void _previousPoint() {
    if (!_sessionState.hasPrevious) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _sessionState = _sessionState.copyWith(
        currentIndex: _sessionState.currentIndex - 1,
        elapsedSeconds: 0,
      );
    });

    _resetProgressAnimation();
  }

  void _nextPoint() {
    if (!_sessionState.hasNext) {
      _completeSession();
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _sessionState = _sessionState.copyWith(
        currentIndex: _sessionState.currentIndex + 1,
        elapsedSeconds: 0,
      );
    });

    _resetProgressAnimation();
  }

  void _resetProgressAnimation() {
    _progressController.reset();
    if (widget.group.autoAdvance && !_sessionState.isPaused) {
      _progressController.forward();
    }
  }

  void _completeSession() {
    HapticFeedback.heavyImpact();
    setState(() {
      _sessionState = _sessionState.copyWith(isComplete: true);
    });
    _timer?.cancel();

    // Mark group as used
    context.read<PulpitCubit>().markGroupUsed(widget.group.id);

    // Show completion dialog
    _showCompletionDialog();
  }

  Future<void> _showCompletionDialog() async {
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.answeredColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCircle, color: AppTheme.answeredColor),
            ),
            const SizedBox(width: 12),
            const Text('Session Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve completed "${widget.group.title}"',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildStatRow(LucideIcons.list, '${widget.group.points.length} prayer points'),
            _buildStatRow(
              LucideIcons.clock,
              'Used ${widget.group.timesUsed + 1} times',
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            icon: const Icon(LucideIcons.trash2, color: AppTheme.urgentColor),
            label: const Text('Delete Group', style: TextStyle(color: AppTheme.urgentColor)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, 'keep'),
            icon: const Icon(LucideIcons.save),
            label: const Text('Keep for Later'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (action == 'delete') {
      await context.read<PulpitCubit>().deleteGroup(widget.group.id);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildStatRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Session?'),
        content: const Text('Are you sure you want to exit this pulpit session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.urgentColor,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentPoint = _sessionState.currentPoint;
    final nextPoint = _sessionState.nextPoint;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFF1a1a2e),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              _buildTopBar(isDark),

              // Progress indicator
              if (widget.group.autoAdvance) _buildProgressBar(),

              // Main Content
              Expanded(
                child: currentPoint != null
                    ? _buildCurrentPointDisplay(currentPoint, isDark)
                    : const Center(child: Text('No prayer points')),
              ),

              // Next Preview
              if (nextPoint != null) _buildNextPreview(nextPoint, isDark),

              // Controls
              _buildControls(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _confirmExit,
            icon: const Icon(LucideIcons.x, color: Colors.white70),
            tooltip: 'Exit',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.group.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Point ${_sessionState.currentIndex + 1} of ${widget.group.points.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          // Timer Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  widget.group.autoAdvance ? LucideIcons.timerReset : LucideIcons.timer,
                  size: 18,
                  color: widget.group.autoAdvance
                      ? AppTheme.answeredColor
                      : Colors.white70,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.group.autoAdvance
                      ? _sessionState.remainingTimeFormatted
                      : _sessionState.elapsedTimeFormatted,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressController.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withAlpha(180),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentPointDisplay(PulpitPrayerPoint point, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Point Number Badge
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(
                    (30 + (20 * _pulseController.value)).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.primaryColor.withAlpha(100),
                    width: 2,
                  ),
                ),
                child: Text(
                  'PRAYER POINT ${_sessionState.currentIndex + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            point.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),

          // Description
          if (point.description != null && point.description!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                point.description!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Scriptures
          if (point.scriptures.isNotEmpty) ...[
            ...point.scriptures.map((scripture) => _buildScriptureCard(scripture)),
          ],
        ],
      ),
    );
  }

  Widget _buildScriptureCard(ScriptureReference scripture) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryColor.withAlpha(30),
            AppTheme.secondaryColor.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryColor.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bookOpen, size: 18, color: AppTheme.secondaryColor),
              const SizedBox(width: 10),
              Text(
                scripture.reference,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          if (scripture.text != null && scripture.text!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '"${scripture.text}"',
              style: GoogleFonts.libreBaskerville(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.white.withAlpha(220),
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextPreview(PulpitPrayerPoint nextPoint, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.chevronRight, size: 20, color: Colors.white54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UP NEXT',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextPoint.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous
          _ControlButton(
            icon: LucideIcons.skipBack,
            label: 'Previous',
            onPressed: _sessionState.hasPrevious ? _previousPoint : null,
          ),

          // Pause/Resume
          _ControlButton(
            icon: _sessionState.isPaused ? LucideIcons.play : LucideIcons.pause,
            label: _sessionState.isPaused ? 'Resume' : 'Pause',
            onPressed: _togglePause,
            isPrimary: true,
          ),

          // Next
          _ControlButton(
            icon: _sessionState.hasNext ? LucideIcons.skipForward : LucideIcons.checkCircle,
            label: _sessionState.hasNext ? 'Next' : 'Complete',
            onPressed: _nextPoint,
          ),
        ],
      ),
    );
  }
}

/// Control button widget.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isPrimary ? 72 : 56,
              height: isPrimary ? 72 : 56,
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppTheme.primaryColor
                    : Colors.white.withAlpha(15),
                shape: BoxShape.circle,
                border: isPrimary
                    ? null
                    : Border.all(color: Colors.white.withAlpha(30)),
              ),
              child: Icon(
                icon,
                size: isPrimary ? 32 : 24,
                color: isPrimary ? Colors.white : Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
