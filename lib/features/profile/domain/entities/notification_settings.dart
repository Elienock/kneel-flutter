import 'package:equatable/equatable.dart';

/// Represents the user's notification preferences.
class NotificationSettings extends Equatable {
  final bool morningRemindersEnabled;
  final bool answeredPrayerAlertsEnabled;
  final DateTime reminderTime;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationSettings({
    this.morningRemindersEnabled = true,
    this.answeredPrayerAlertsEnabled = true,
    required this.reminderTime,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  /// Creates default notification settings.
  factory NotificationSettings.defaults() {
    return NotificationSettings(
      morningRemindersEnabled: true,
      answeredPrayerAlertsEnabled: true,
      reminderTime: DateTime(2024, 1, 1, 7, 0), // 7:00 AM
      soundEnabled: true,
      vibrationEnabled: true,
    );
  }

  /// Creates a copy of this settings with the given fields replaced.
  NotificationSettings copyWith({
    bool? morningRemindersEnabled,
    bool? answeredPrayerAlertsEnabled,
    DateTime? reminderTime,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      morningRemindersEnabled: morningRemindersEnabled ?? this.morningRemindersEnabled,
      answeredPrayerAlertsEnabled: answeredPrayerAlertsEnabled ?? this.answeredPrayerAlertsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  @override
  List<Object?> get props => [
        morningRemindersEnabled,
        answeredPrayerAlertsEnabled,
        reminderTime,
        soundEnabled,
        vibrationEnabled,
      ];
}
