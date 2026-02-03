import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';

/// Animated victory overlay shown when a streak increases.
/// Features particle effects, scaling fire icon, and celebratory message.
class StreakVictoryOverlay extends StatefulWidget {
  final int newStreak;
  final int previousStreak;
  final bool isNewStreak;
  final String message;
  final VoidCallback? onDismiss;

  const StreakVictoryOverlay({
    super.key,
    required this.newStreak,
    required this.previousStreak,
    this.isNewStreak = false,
    this.message = 'Streak Up!',
    this.onDismiss,
  });

  /// Show the victory overlay as a modal.
  static Future<void> show(
    BuildContext context, {
    required int newStreak,
    required int previousStreak,
    bool isNewStreak = false,
    String? message,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StreakVictoryOverlay(
          newStreak: newStreak,
          previousStreak: previousStreak,
          isNewStreak: isNewStreak,
          message: message ??
              (isNewStreak
                  ? 'New Streak Started!'
                  : newStreak > previousStreak
                      ? 'Streak Up!'
                      : 'Keep Going!'),
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  @override
  State<StreakVictoryOverlay> createState() => _StreakVictoryOverlayState();
}

class _StreakVictoryOverlayState extends State<StreakVictoryOverlay>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _scaleController;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Initialize particles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: 0.5 + (_random.nextDouble() - 0.5) * 0.3,
        y: 0.5,
        vx: (_random.nextDouble() - 0.5) * 0.02,
        vy: -_random.nextDouble() * 0.02 - 0.005,
        size: _random.nextDouble() * 8 + 4,
        color: _getRandomColor(),
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
      ));
    }

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Auto-dismiss after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  Color _getRandomColor() {
    final colors = [
      AppTheme.goldenPromise,
      AppTheme.primaryColor,
      const Color(0xFFFF9800), // Orange
      const Color(0xFFE91E63), // Pink
      Colors.white,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _particleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Particle effects
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(300, 300),
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleController.value,
                    ),
                  );
                },
              ),

              // Main content
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.elasticOut,
                ),
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withAlpha(220),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(100),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated fire icon
          _buildFireIcon(),
          const SizedBox(height: 16),

          // Streak count with animation
          _buildStreakCount(),
          const SizedBox(height: 8),

          // Message
          Text(
            widget.message,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
                begin: 0.3,
                end: 0,
                delay: 300.ms,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 4),

          // Sub-message
          Text(
            _getSubMessage(),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

          const SizedBox(height: 20),

          // Tap to dismiss hint
          Text(
            'Tap anywhere to continue',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white54,
            ),
          ).animate().fadeIn(delay: 1500.ms, duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildFireIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(
          LucideIcons.flame,
          size: 48,
          color: AppTheme.goldenPromise,
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.elasticOut,
        )
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.08, 1.08),
          duration: 1000.ms,
          curve: Curves.easeInOut,
        )
        .shimmer(
          duration: 1500.ms,
          color: AppTheme.goldenPromise.withAlpha(100),
        );
  }

  Widget _buildStreakCount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${widget.newStreak}',
          style: GoogleFonts.outfit(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ).animate().fadeIn(duration: 300.ms).scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(width: 8),
        Text(
          widget.newStreak == 1 ? 'day' : 'days',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
      ],
    );
  }

  String _getSubMessage() {
    if (widget.isNewStreak && widget.previousStreak > 0) {
      return 'Welcome back, warrior!';
    }
    if (widget.newStreak == 1) {
      return 'Your journey begins!';
    }
    if (widget.newStreak == 7) {
      return 'One week strong!';
    }
    if (widget.newStreak == 14) {
      return 'Two weeks of devotion!';
    }
    if (widget.newStreak == 30) {
      return 'A month of faithfulness!';
    }
    if (widget.newStreak == 100) {
      return 'Legendary dedication!';
    }
    if (widget.newStreak > widget.previousStreak) {
      return 'Keep the fire burning!';
    }
    return 'Stay faithful!';
  }
}

/// Particle data for confetti effect.
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// Custom painter for particle effects.
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Update position based on progress
      final t = progress;
      final x = particle.x + particle.vx * t * 60;
      final y = particle.y + particle.vy * t * 60 + 0.001 * t * t * 60 * 60; // gravity
      final rotation = particle.rotation + particle.rotationSpeed * t * 60;

      // Fade out
      final alpha = (1 - t).clamp(0.0, 1.0);

      if (alpha <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withAlpha((alpha * 255).round())
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(rotation);

      // Draw star shape
      final path = Path();
      for (int i = 0; i < 4; i++) {
        final angle = i * pi / 2;
        final radius = particle.size * (1 - t * 0.5);
        if (i == 0) {
          path.moveTo(cos(angle) * radius, sin(angle) * radius);
        } else {
          path.lineTo(cos(angle) * radius, sin(angle) * radius);
        }
        final innerAngle = angle + pi / 4;
        final innerRadius = radius * 0.4;
        path.lineTo(cos(innerAngle) * innerRadius, sin(innerAngle) * innerRadius);
      }
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
