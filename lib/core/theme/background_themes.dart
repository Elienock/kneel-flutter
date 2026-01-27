import 'package:flutter/material.dart';

/// Background theme presets for the app.
class BackgroundThemes {
  static const String purple = 'purple';
  static const String blue = 'blue';
  static const String green = 'green';
  static const String orange = 'orange';
  static const String pink = 'pink';

  /// All available theme keys.
  static const List<String> all = [purple, blue, green, orange, pink];

  /// Gets the gradient colors for a theme.
  static List<Color> getGradientColors(String themeKey, {bool isDark = false}) {
    switch (themeKey) {
      case purple:
        return isDark
            ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
            : [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)];
      case blue:
        return isDark
            ? [const Color(0xFF0d1b2a), const Color(0xFF1b263b)]
            : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)];
      case green:
        return isDark
            ? [const Color(0xFF1a2f1a), const Color(0xFF0d1f0d)]
            : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)];
      case orange:
        return isDark
            ? [const Color(0xFF2d1f10), const Color(0xFF3d2a15)]
            : [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)];
      case pink:
        return isDark
            ? [const Color(0xFF2d1a2d), const Color(0xFF3d1f3d)]
            : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD9)];
      default:
        return isDark
            ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
            : [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)];
    }
  }

  /// Gets the primary color for a theme.
  static Color getPrimaryColor(String themeKey) {
    switch (themeKey) {
      case purple:
        return const Color(0xFF673AB7);
      case blue:
        return const Color(0xFF2196F3);
      case green:
        return const Color(0xFF4CAF50);
      case orange:
        return const Color(0xFFFF9800);
      case pink:
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF673AB7);
    }
  }

  /// Gets the theme display name.
  static String getDisplayName(String themeKey) {
    switch (themeKey) {
      case purple:
        return 'Royal Purple';
      case blue:
        return 'Ocean Blue';
      case green:
        return 'Forest Green';
      case orange:
        return 'Sunset Orange';
      case pink:
        return 'Rose Pink';
      default:
        return 'Royal Purple';
    }
  }

  /// Creates a gradient decoration for a theme.
  static BoxDecoration getGradientDecoration(
    String themeKey, {
    bool isDark = false,
    double opacity = 1.0,
  }) {
    final colors = getGradientColors(themeKey, isDark: isDark);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors.map((c) => c.withValues(alpha: opacity)).toList(),
      ),
    );
  }
}

/// Widget that displays a preview of a background theme.
class BackgroundThemePreview extends StatelessWidget {
  final String themeKey;
  final bool isSelected;
  final VoidCallback? onTap;

  const BackgroundThemePreview({
    super.key,
    required this.themeKey,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? BackgroundThemes.getPrimaryColor(themeKey)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BackgroundThemes.getGradientDecoration(
              themeKey,
              isDark: isDark,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: BackgroundThemes.getPrimaryColor(themeKey),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: BackgroundThemes.getPrimaryColor(themeKey),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A picker widget for selecting background themes.
class BackgroundThemePicker extends StatelessWidget {
  final String selectedTheme;
  final ValueChanged<String>? onThemeChanged;

  const BackgroundThemePicker({
    super.key,
    required this.selectedTheme,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: BackgroundThemes.all.map((themeKey) {
        return BackgroundThemePreview(
          themeKey: themeKey,
          isSelected: selectedTheme == themeKey,
          onTap: () => onThemeChanged?.call(themeKey),
        );
      }).toList(),
    );
  }
}
