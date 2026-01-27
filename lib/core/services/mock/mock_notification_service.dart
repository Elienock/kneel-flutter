import 'package:injectable/injectable.dart';
import 'package:quick_church/core/services/interfaces/i_notification_service.dart';
import 'package:quick_church/features/profile/domain/entities/notification_settings.dart';

/// Mock implementation of [INotificationService] for development and testing.
/// Simulates scheduling and managing notifications without actual system integration.
@LazySingleton(as: INotificationService)
class MockNotificationService implements INotificationService {
  NotificationSettings _settings = NotificationSettings.defaults();
  final Map<int, _ScheduledNotification> _scheduledNotifications = {};

  static const _mockDelay = Duration(milliseconds: 300);

  @override
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool repeating = false,
  }) async {
    await Future.delayed(_mockDelay);

    _scheduledNotifications[id] = _ScheduledNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      repeating: repeating,
    );
  }

  @override
  Future<void> cancelReminder(int id) async {
    await Future.delayed(_mockDelay);
    _scheduledNotifications.remove(id);
  }

  @override
  Future<void> cancelAllReminders() async {
    await Future.delayed(_mockDelay);
    _scheduledNotifications.clear();
  }

  @override
  Future<NotificationSettings> getSettings() async {
    await Future.delayed(_mockDelay);
    return _settings;
  }

  @override
  Future<void> updateSettings(NotificationSettings settings) async {
    await Future.delayed(_mockDelay);
    _settings = settings;
  }

  @override
  Future<bool> requestPermissions() async {
    await Future.delayed(_mockDelay);
    // Mock: always grant permissions
    return true;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    await Future.delayed(_mockDelay);
    // Mock: always return true
    return true;
  }
}

class _ScheduledNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final bool repeating;

  _ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.repeating,
  });
}
