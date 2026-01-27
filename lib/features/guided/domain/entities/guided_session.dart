import 'package:equatable/equatable.dart';

/// Represents a guided prayer/meditation session.
class GuidedSession extends Equatable {
  final String id;
  final String title;
  final String description;
  final GuidedSessionType type;
  final int durationMinutes;
  final String? imageUrl;
  final String? audioUrl;
  final bool isPremium;
  final List<String> tags;

  const GuidedSession({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.durationMinutes,
    this.imageUrl,
    this.audioUrl,
    this.isPremium = false,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        durationMinutes,
        imageUrl,
        audioUrl,
        isPremium,
        tags,
      ];
}

/// Types of guided sessions available.
enum GuidedSessionType {
  scriptureMeditation,
  guidedPrayer,
  worshipSession,
  breathingExercise,
}

extension GuidedSessionTypeExtension on GuidedSessionType {
  String get displayName {
    switch (this) {
      case GuidedSessionType.scriptureMeditation:
        return 'Scripture Meditation';
      case GuidedSessionType.guidedPrayer:
        return 'Guided Prayer';
      case GuidedSessionType.worshipSession:
        return 'Worship Session';
      case GuidedSessionType.breathingExercise:
        return 'Breathing Exercise';
    }
  }

  String get icon {
    switch (this) {
      case GuidedSessionType.scriptureMeditation:
        return 'book-open';
      case GuidedSessionType.guidedPrayer:
        return 'heart-handshake';
      case GuidedSessionType.worshipSession:
        return 'music';
      case GuidedSessionType.breathingExercise:
        return 'wind';
    }
  }
}
