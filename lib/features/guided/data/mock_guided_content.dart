import 'package:quick_church/features/guided/domain/entities/guided_session.dart';

/// Mock guided session content for development.
class MockGuidedContent {
  static const List<GuidedSession> sessions = [
    // Scripture Meditations
    GuidedSession(
      id: 'psalm-23',
      title: 'Psalm 23: The Lord is My Shepherd',
      description: 'A peaceful meditation on God\'s care and guidance through the beloved 23rd Psalm.',
      type: GuidedSessionType.scriptureMeditation,
      durationMinutes: 10,
      tags: ['peace', 'trust', 'psalms'],
    ),
    GuidedSession(
      id: 'lords-prayer',
      title: 'The Lord\'s Prayer',
      description: 'A guided journey through each phrase of Jesus\' model prayer.',
      type: GuidedSessionType.scriptureMeditation,
      durationMinutes: 15,
      tags: ['jesus', 'prayer', 'teaching'],
    ),
    GuidedSession(
      id: 'beatitudes',
      title: 'The Beatitudes',
      description: 'Reflect on Jesus\' teachings on blessedness from the Sermon on the Mount.',
      type: GuidedSessionType.scriptureMeditation,
      durationMinutes: 12,
      tags: ['jesus', 'blessing', 'sermon'],
    ),

    // Guided Prayers
    GuidedSession(
      id: 'morning-offering',
      title: 'Morning Offering',
      description: 'Start your day by offering it to God with this gentle guided prayer.',
      type: GuidedSessionType.guidedPrayer,
      durationMinutes: 5,
      tags: ['morning', 'dedication', 'daily'],
    ),
    GuidedSession(
      id: 'examen',
      title: 'Daily Examen',
      description: 'A prayerful review of your day through gratitude and reflection.',
      type: GuidedSessionType.guidedPrayer,
      durationMinutes: 10,
      tags: ['evening', 'reflection', 'gratitude'],
    ),
    GuidedSession(
      id: 'intercessory',
      title: 'Intercessory Prayer',
      description: 'Guided intercession for loved ones, community, and the world.',
      type: GuidedSessionType.guidedPrayer,
      durationMinutes: 8,
      tags: ['intercession', 'others', 'compassion'],
    ),
    GuidedSession(
      id: 'forgiveness',
      title: 'Prayer of Forgiveness',
      description: 'Release burdens and find freedom through guided forgiveness prayer.',
      type: GuidedSessionType.guidedPrayer,
      durationMinutes: 12,
      isPremium: true,
      tags: ['forgiveness', 'healing', 'freedom'],
    ),

    // Worship Sessions
    GuidedSession(
      id: 'praise-adoration',
      title: 'Praise & Adoration',
      description: 'Enter into worship with guided prompts for praising God.',
      type: GuidedSessionType.worshipSession,
      durationMinutes: 10,
      tags: ['worship', 'praise', 'adoration'],
    ),
    GuidedSession(
      id: 'thanksgiving',
      title: 'Thanksgiving Worship',
      description: 'Cultivate a grateful heart through guided thanksgiving.',
      type: GuidedSessionType.worshipSession,
      durationMinutes: 8,
      tags: ['thanksgiving', 'gratitude', 'worship'],
    ),

    // Breathing Exercises
    GuidedSession(
      id: 'breath-prayer',
      title: 'Breath Prayer',
      description: 'Combine breathing with simple prayer phrases for centering.',
      type: GuidedSessionType.breathingExercise,
      durationMinutes: 5,
      tags: ['breathing', 'centering', 'calm'],
    ),
    GuidedSession(
      id: 'peace-calm',
      title: 'Peace & Calm',
      description: 'A breathing exercise to release anxiety and find God\'s peace.',
      type: GuidedSessionType.breathingExercise,
      durationMinutes: 7,
      tags: ['anxiety', 'peace', 'breathing'],
    ),
  ];

  /// Get sessions by type.
  static List<GuidedSession> getByType(GuidedSessionType type) {
    return sessions.where((s) => s.type == type).toList();
  }

  /// Get featured sessions (for home page).
  static List<GuidedSession> getFeatured() {
    return sessions.take(4).toList();
  }

  /// Get free sessions only.
  static List<GuidedSession> getFreeSessions() {
    return sessions.where((s) => !s.isPremium).toList();
  }
}
