import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Types of guided content available.
enum GuidedContentType {
  scripturePlan,      // Multi-day Bible reading/meditation plan
  guidedPrayer,       // Text-based prayer guide (TTS ready)
  worshipSession,     // Links to YouTube/Spotify worship content
  breathingExercise,  // Visual breathing guide with timers
}

extension GuidedContentTypeExtension on GuidedContentType {
  String get displayName {
    switch (this) {
      case GuidedContentType.scripturePlan:
        return 'Scripture Plan';
      case GuidedContentType.guidedPrayer:
        return 'Guided Prayer';
      case GuidedContentType.worshipSession:
        return 'Worship';
      case GuidedContentType.breathingExercise:
        return 'Breathing';
    }
  }

  String get shortName {
    switch (this) {
      case GuidedContentType.scripturePlan:
        return 'Plan';
      case GuidedContentType.guidedPrayer:
        return 'Prayer';
      case GuidedContentType.worshipSession:
        return 'Worship';
      case GuidedContentType.breathingExercise:
        return 'Breathe';
    }
  }

  Color get color {
    switch (this) {
      case GuidedContentType.scripturePlan:
        return const Color(0xFF6366F1); // Indigo
      case GuidedContentType.guidedPrayer:
        return const Color(0xFFEC4899); // Pink
      case GuidedContentType.worshipSession:
        return const Color(0xFFF59E0B); // Amber
      case GuidedContentType.breathingExercise:
        return const Color(0xFF14B8A6); // Teal
    }
  }
}

/// A guided content plan (like YouVersion Plans).
class GuidedPlan extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final GuidedContentType type;
  final int totalDays;
  final int completedDays;
  final String imageGradientStart; // Hex color
  final String imageGradientEnd;   // Hex color
  final String? imageUrl;
  final bool isPremium;
  final List<String> tags;
  final List<PlanDay> days;

  const GuidedPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.type,
    required this.totalDays,
    this.completedDays = 0,
    required this.imageGradientStart,
    required this.imageGradientEnd,
    this.imageUrl,
    this.isPremium = false,
    this.tags = const [],
    this.days = const [],
  });

  double get progress => totalDays > 0 ? completedDays / totalDays : 0;
  bool get isStarted => completedDays > 0;
  bool get isCompleted => completedDays >= totalDays;

  Color get gradientStart => Color(int.parse(imageGradientStart.replaceFirst('#', '0xFF')));
  Color get gradientEnd => Color(int.parse(imageGradientEnd.replaceFirst('#', '0xFF')));

  @override
  List<Object?> get props => [id, title, type, totalDays, completedDays];
}

/// A single day within a plan.
class PlanDay extends Equatable {
  final int dayNumber;
  final String title;
  final bool isCompleted;
  final PlanDayContent content;

  const PlanDay({
    required this.dayNumber,
    required this.title,
    this.isCompleted = false,
    required this.content,
  });

  @override
  List<Object?> get props => [dayNumber, title, isCompleted];
}

/// Content for a plan day - can be different types.
abstract class PlanDayContent extends Equatable {
  const PlanDayContent();
}

/// Scripture/text content for reading and TTS.
class ScriptureContent extends PlanDayContent {
  final String reference;        // e.g., "Psalm 23:1-6"
  final String scriptureText;    // Full scripture passage
  final String reflection;       // Reflection/devotional text
  final String? prayer;          // Optional closing prayer

  const ScriptureContent({
    required this.reference,
    required this.scriptureText,
    required this.reflection,
    this.prayer,
  });

  /// Full text for TTS
  String get fullTextForTTS => '''
$reference

$scriptureText

Reflection:
$reflection

${prayer != null ? 'Prayer:\n$prayer' : ''}
''';

  @override
  List<Object?> get props => [reference, scriptureText, reflection, prayer];
}

/// Prayer guide content for TTS.
class PrayerContent extends PlanDayContent {
  final String introduction;
  final List<PrayerSection> sections;
  final String closingPrayer;

  const PrayerContent({
    required this.introduction,
    required this.sections,
    required this.closingPrayer,
  });

  String get fullTextForTTS {
    final sectionsText = sections.map((s) => '${s.title}\n${s.content}').join('\n\n');
    return '''
$introduction

$sectionsText

$closingPrayer
''';
  }

  @override
  List<Object?> get props => [introduction, sections, closingPrayer];
}

class PrayerSection extends Equatable {
  final String title;
  final String content;
  final String? prompt; // Optional reflection prompt

  const PrayerSection({
    required this.title,
    required this.content,
    this.prompt,
  });

  @override
  List<Object?> get props => [title, content, prompt];
}

/// Worship content linking to external sources.
class WorshipContent extends PlanDayContent {
  final String description;
  final List<WorshipLink> links;
  final String? reflectionPrompt;

  const WorshipContent({
    required this.description,
    required this.links,
    this.reflectionPrompt,
  });

  @override
  List<Object?> get props => [description, links];
}

class WorshipLink extends Equatable {
  final String title;
  final String artist;
  final String url;
  final WorshipLinkType type;
  final String? thumbnailUrl;

  const WorshipLink({
    required this.title,
    required this.artist,
    required this.url,
    required this.type,
    this.thumbnailUrl,
  });

  @override
  List<Object?> get props => [title, url, type];
}

enum WorshipLinkType { youtube, spotify, appleMusic, other }

/// Breathing exercise content with visual guide parameters.
class BreathingContent extends PlanDayContent {
  final String introduction;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int cycles;
  final String? scripture;        // Optional verse to focus on
  final String? closingReflection;

  const BreathingContent({
    required this.introduction,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
    required this.cycles,
    this.scripture,
    this.closingReflection,
  });

  int get totalSeconds => (inhaleSeconds + holdSeconds + exhaleSeconds) * cycles;
  int get totalMinutes => (totalSeconds / 60).ceil();

  @override
  List<Object?> get props => [inhaleSeconds, holdSeconds, exhaleSeconds, cycles];
}

// ============================================================================
// Legacy support (keeping old model for backward compatibility during migration)
// ============================================================================

/// @deprecated Use GuidedPlan instead
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
  List<Object?> get props => [id, title, description, type, durationMinutes];
}

/// @deprecated Use GuidedContentType instead
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
