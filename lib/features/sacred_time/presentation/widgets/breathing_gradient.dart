import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A slow-moving, breathing mesh gradient background for the Sacred Time sanctuary.
/// Creates a calming visual effect that "breathes" with subtle color shifts.
class BreathingGradient extends StatefulWidget {
  final Duration breathCycle;
  final List<Color>? colors;
  final Widget? child;

  const BreathingGradient({
    super.key,
    this.breathCycle = const Duration(seconds: 8),
    this.colors,
    this.child,
  });

  @override
  State<BreathingGradient> createState() => _BreathingGradientState();
}

class _BreathingGradientState extends State<BreathingGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.breathCycle,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultColors = widget.colors ??
        [
          const Color(0xFF673AB7), // Kneel Purple
          const Color(0xFF4A148C), // Deep Purple
          const Color(0xFF1A1A2E), // Deep Navy
          const Color(0xFF0D0D0D), // Near Black
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final breathValue = math.sin(_controller.value * math.pi * 2) * 0.5 + 0.5;
        final shiftValue = _controller.value;

        return CustomPaint(
          painter: _MeshGradientPainter(
            colors: defaultColors,
            breathValue: breathValue,
            shiftValue: shiftValue,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  final List<Color> colors;
  final double breathValue;
  final double shiftValue;

  _MeshGradientPainter({
    required this.colors,
    required this.breathValue,
    required this.shiftValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create multiple layered gradients for mesh effect
    final baseGradient = RadialGradient(
      center: Alignment(
        math.sin(shiftValue * math.pi * 2) * 0.3,
        math.cos(shiftValue * math.pi * 2) * 0.3 - 0.3,
      ),
      radius: 1.2 + breathValue * 0.2,
      colors: [
        colors[0].withAlpha((150 + breathValue * 50).toInt()),
        colors[1].withAlpha((100 + breathValue * 30).toInt()),
        colors[2],
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final overlayGradient = RadialGradient(
      center: Alignment(
        math.cos(shiftValue * math.pi * 2 + math.pi) * 0.4,
        math.sin(shiftValue * math.pi * 2 + math.pi) * 0.4 + 0.4,
      ),
      radius: 0.8 + breathValue * 0.15,
      colors: [
        colors[1].withAlpha((80 + breathValue * 40).toInt()),
        colors[2].withAlpha((60 + breathValue * 20).toInt()),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    // Base dark background
    canvas.drawRect(rect, Paint()..color = colors[3]);

    // Draw layered gradients
    canvas.drawRect(rect, Paint()..shader = baseGradient.createShader(rect));
    canvas.drawRect(rect, Paint()..shader = overlayGradient.createShader(rect));

    // Subtle vignette effect
    final vignetteGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.transparent,
        Colors.black.withAlpha(100),
      ],
      stops: const [0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = vignetteGradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) {
    return oldDelegate.breathValue != breathValue ||
        oldDelegate.shiftValue != shiftValue;
  }
}

/// A simpler breathing circle indicator that pulses with the breath.
class BreathingCircle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration breathCycle;
  final Widget? child;

  const BreathingCircle({
    super.key,
    this.size = 200,
    this.color = const Color(0xFF673AB7),
    this.breathCycle = const Duration(seconds: 4),
    this.child,
  });

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.breathCycle,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withAlpha((_opacityAnimation.value * 255).toInt()),
                  widget.color.withAlpha((_opacityAnimation.value * 100).toInt()),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withAlpha((_opacityAnimation.value * 80).toInt()),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
