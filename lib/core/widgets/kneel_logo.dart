import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_church/core/theme/app_theme.dart';

/// Official Kneel logo widget with support for light and dark backgrounds.
///
/// Usage:
/// - [KneelLogo.dark] - For dark/black backgrounds (logo with purple container)
/// - [KneelLogo.light] - For white/light backgrounds (logo on transparent bg)
/// - [KneelLogo.sidebar] - Compact version for navigation sidebar
class KneelLogo extends StatelessWidget {
  /// Logo variant for dark backgrounds (includes purple container)
  static const String _darkBgAsset = 'assets/icon/logo_darkBG.png';

  /// Logo variant for light backgrounds (transparent background)
  static const String _lightBgAsset = 'assets/icon/logo_lightBG.png';

  /// Default height for the main logo
  static const double defaultHeight = 120.0;

  /// Default height for sidebar logo
  static const double sidebarHeight = 48.0;

  final String _assetPath;
  final double _height;
  final bool _showBrandName;
  final bool _showElevation;
  final double? _elevation;
  final Color? _shadowColor;

  const KneelLogo._({
    required String assetPath,
    required double height,
    bool showBrandName = false,
    bool showElevation = false,
    double? elevation,
    Color? shadowColor,
  })  : _assetPath = assetPath,
        _height = height,
        _showBrandName = showBrandName,
        _showElevation = showElevation,
        _elevation = elevation,
        _shadowColor = shadowColor;

  /// Creates a logo for dark/black backgrounds.
  /// The purple background of the logo creates a 'brand container' effect.
  ///
  /// [height] - Logo height (default: 120px)
  /// [showBrandName] - Show "Kneel" text below logo
  /// [showElevation] - Add shadow/elevation effect (recommended for dark bg)
  /// [elevation] - Custom elevation value (default: 8)
  /// [shadowColor] - Custom shadow color (default: primaryColor with 40% opacity)
  factory KneelLogo.dark({
    double height = defaultHeight,
    bool showBrandName = false,
    bool showElevation = true,
    double? elevation,
    Color? shadowColor,
  }) {
    return KneelLogo._(
      assetPath: _darkBgAsset,
      height: height,
      showBrandName: showBrandName,
      showElevation: showElevation,
      elevation: elevation,
      shadowColor: shadowColor,
    );
  }

  /// Creates a logo for light/white backgrounds.
  /// Uses the logo with transparent background.
  ///
  /// [height] - Logo height (default: 120px)
  /// [showBrandName] - Show "Kneel" text below logo
  factory KneelLogo.light({
    double height = defaultHeight,
    bool showBrandName = false,
  }) {
    return KneelLogo._(
      assetPath: _lightBgAsset,
      height: height,
      showBrandName: showBrandName,
      showElevation: false,
    );
  }

  /// Creates a compact logo for sidebar/navigation.
  /// Smaller size optimized for navigation aesthetics.
  ///
  /// [forDarkBackground] - Use dark bg variant (default: auto-detect from theme)
  factory KneelLogo.sidebar({bool? forDarkBackground}) {
    // Sidebar uses dark bg logo by default as it pops better
    final assetPath = (forDarkBackground ?? true) ? _darkBgAsset : _lightBgAsset;
    return KneelLogo._(
      assetPath: assetPath,
      height: sidebarHeight,
      showBrandName: false,
      showElevation: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoWidget = _buildLogo(context);

    if (_showBrandName) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoWidget,
          const SizedBox(height: 16),
          Text(
            'Kneel',
            style: GoogleFonts.outfit(
              fontSize: _height * 0.3,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      );
    }

    return logoWidget;
  }

  Widget _buildLogo(BuildContext context) {
    Widget logoImage = Image.asset(
      _assetPath,
      height: _height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to app_icon if specific variant fails
        return Image.asset(
          'assets/icon/app_icon.png',
          height: _height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            // Ultimate fallback to icon
            return Container(
              height: _height,
              width: _height,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(_height * 0.2),
              ),
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: _height * 0.5,
              ),
            );
          },
        );
      },
    );

    if (_showElevation) {
      final effectiveElevation = _elevation ?? 8.0;
      final effectiveShadowColor =
          _shadowColor ?? AppTheme.primaryColor.withValues(alpha: 0.4);

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_height * 0.2),
          boxShadow: [
            BoxShadow(
              color: effectiveShadowColor,
              blurRadius: effectiveElevation * 2.5,
              spreadRadius: effectiveElevation * 0.5,
              offset: Offset(0, effectiveElevation),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_height * 0.2),
          child: logoImage,
        ),
      );
    }

    return logoImage;
  }
}

/// Animated version of KneelLogo with fade-in and scale effects.
/// Used for loading screens and splash pages.
class AnimatedKneelLogo extends StatelessWidget {
  final KneelLogo logo;
  final Duration duration;
  final Curve curve;

  const AnimatedKneelLogo({
    super.key,
    required this.logo,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: child,
          ),
        );
      },
      child: logo,
    );
  }
}
