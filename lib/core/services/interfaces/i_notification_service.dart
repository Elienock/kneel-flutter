import 'package:quick_church/features/profile/domain/entities/notification_settings.dart';

/// Abstract interface for notification services.
/// Handles scheduling and managing prayer reminders.
abstract class INotificationService {
  /// Schedules a reminder notification at the specified time.
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool repeating = false,
  });

  /// Cancels a scheduled reminder by its ID.
  Future<void> cancelReminder(int id);

  /// Cancels all scheduled reminders.
  Future<void> cancelAllReminders();

  /// Gets the current notification settings.
  Future<NotificationSettings> getSettings();

  /// Updates the notification settings.
  Future<void> updateSettings(NotificationSettings settings);

  /// Requests notification permissions from the user.
  Future<bool> requestPermissions();

  /// Checks if notifications are currently enabled.
  Future<bool> areNotificationsEnabled();
}
