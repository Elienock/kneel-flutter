import 'package:equatable/equatable.dart';

/// Represents the user's app preferences.
class UserPreferences extends Equatable {
  final String locale;
  final bool biometricEnabled;
  final String themeMode; // 'light', 'dark', 'system'
  final String backgroundTheme;
  final bool hapticFeedbackEnabled;

  const UserPreferences({
    this.locale = 'en',
    this.biometricEnabled = false,
    this.themeMode = 'system',
    this.backgroundTheme = 'purple',
    this.hapticFeedbackEnabled = true,
  });

  /// Creates default user preferences.
  factory UserPreferences.defaults() {
    return const UserPreferences();
  }

  /// Creates a copy of this preferences with the given fields replaced.
  UserPreferences copyWith({
    String? locale,
    bool? biometricEnabled,
    String? themeMode,
    String? backgroundTheme,
    bool? hapticFeedbackEnabled,
  }) {
    return UserPreferences(
      locale: locale ?? this.locale,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      themeMode: themeMode ?? this.themeMode,
      backgroundTheme: backgroundTheme ?? this.backgroundTheme,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }

  @override
  List<Object?> get props => [
        locale,
        biometricEnabled,
        themeMode,
        backgroundTheme,
        hapticFeedbackEnabled,
      ];
}
