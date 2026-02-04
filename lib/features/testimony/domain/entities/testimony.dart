import 'package:equatable/equatable.dart';

/// Types of testimony entries in the vault.
enum TestimonyType {
  standalone('standalone', 'Testimony'),
  gratitude('gratitude', 'Gratitude'),
  answeredPrayer('answered_prayer', 'Answered Prayer');

  final String dbValue;
  final String displayName;

  const TestimonyType(this.dbValue, this.displayName);

  static TestimonyType fromDbValue(String value) {
    return TestimonyType.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => TestimonyType.standalone,
    );
  }
}

/// Categories for gratitude entries.
enum GratitudeCategory {
  family('family', 'Family'),
  health('health', 'Health'),
  work('work', 'Work'),
  faith('faith', 'Faith'),
  provision('provision', 'Provision'),
  relationships('relationships', 'Relationships'),
  other('other', 'Other');

  final String dbValue;
  final String displayName;

  const GratitudeCategory(this.dbValue, this.displayName);

  static GratitudeCategory? fromDbValue(String? value) {
    if (value == null) return null;
    return GratitudeCategory.values.firstWhere(
      (c) => c.dbValue == value,
      orElse: () => GratitudeCategory.other,
    );
  }
}

/// Represents a testimony entry (standalone, gratitude, or answered prayer).
class Testimony extends Equatable {
  final String id;
  final String userId;
  final TestimonyType type;
  final String title;
  final String? story;

  // For answered prayer type
  final String? prayerId;
  final String? prayerTitle;
  final int prayerCount;
  final int? daysToAnswer;

  // Dates
  final DateTime? eventDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Privacy & Sharing
  final bool isPublic;
  final List<String> sharedWithGroups;

  // Media
  final String? imageUrl;

  // For gratitude type
  final GratitudeCategory? category;

  // Engagement
  final int celebrationCount;
  final int commentCount;

  const Testimony({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.story,
    this.prayerId,
    this.prayerTitle,
    this.prayerCount = 0,
    this.daysToAnswer,
    this.eventDate,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.sharedWithGroups = const [],
    this.imageUrl,
    this.category,
    this.celebrationCount = 0,
    this.commentCount = 0,
  });

  /// Whether this is a standalone testimony (not linked to a prayer).
  bool get isStandalone => type == TestimonyType.standalone;

  /// Whether this is a gratitude entry.
  bool get isGratitude => type == TestimonyType.gratitude;

  /// Whether this is linked to an answered prayer.
  bool get isAnsweredPrayer => type == TestimonyType.answeredPrayer;

  /// Human-readable time since creation.
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  /// Create from Supabase JSON response.
  factory Testimony.fromJson(Map<String, dynamic> json) {
    return Testimony(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: TestimonyType.fromDbValue(json['type'] as String),
      title: json['title'] as String,
      story: json['story'] as String?,
      prayerId: json['prayer_id'] as String?,
      prayerTitle: json['prayer_title'] as String?,
      prayerCount: json['prayer_count'] as int? ?? 0,
      daysToAnswer: json['days_to_answer'] as int?,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isPublic: json['is_public'] as bool? ?? false,
      sharedWithGroups: (json['shared_with_groups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      imageUrl: json['image_url'] as String?,
      category: GratitudeCategory.fromDbValue(json['category'] as String?),
      celebrationCount: json['celebration_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
    );
  }

  /// Convert to JSON for database INSERT.
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'type': type.dbValue,
      'title': title,
      'story': story,
      'prayer_id': prayerId,
      'prayer_title': prayerTitle,
      'prayer_count': prayerCount,
      'days_to_answer': daysToAnswer,
      'event_date': eventDate?.toIso8601String().split('T')[0],
      'is_public': isPublic,
      'shared_with_groups': sharedWithGroups,
      'image_url': imageUrl,
      'category': category?.dbValue,
    };
  }

  /// Convert to full JSON (includes id for updates).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      ...toInsertJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Testimony copyWith({
    String? id,
    String? userId,
    TestimonyType? type,
    String? title,
    String? story,
    bool clearStory = false,
    String? prayerId,
    String? prayerTitle,
    int? prayerCount,
    int? daysToAnswer,
    DateTime? eventDate,
    bool clearEventDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    List<String>? sharedWithGroups,
    String? imageUrl,
    bool clearImageUrl = false,
    GratitudeCategory? category,
    bool clearCategory = false,
    int? celebrationCount,
    int? commentCount,
  }) {
    return Testimony(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      story: clearStory ? null : (story ?? this.story),
      prayerId: prayerId ?? this.prayerId,
      prayerTitle: prayerTitle ?? this.prayerTitle,
      prayerCount: prayerCount ?? this.prayerCount,
      daysToAnswer: daysToAnswer ?? this.daysToAnswer,
      eventDate: clearEventDate ? null : (eventDate ?? this.eventDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      sharedWithGroups: sharedWithGroups ?? this.sharedWithGroups,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      category: clearCategory ? null : (category ?? this.category),
      celebrationCount: celebrationCount ?? this.celebrationCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  @override
  List<Object?> get props => [id, userId, type, title, createdAt, isPublic];
}

/// Stats for the testimony vault.
class TestimonyStats extends Equatable {
  final String? userId;
  final int totalTestimonies;
  final int standaloneCount;
  final int gratitudeCount;
  final int answeredPrayerCount;
  final int publicCount;
  final int totalCelebrations;
  final int gratitudeStreak;
  final int longestGratitudeStreak;
  final DateTime? lastGratitudeDate;

  const TestimonyStats({
    this.userId,
    this.totalTestimonies = 0,
    this.standaloneCount = 0,
    this.gratitudeCount = 0,
    this.answeredPrayerCount = 0,
    this.publicCount = 0,
    this.totalCelebrations = 0,
    this.gratitudeStreak = 0,
    this.longestGratitudeStreak = 0,
    this.lastGratitudeDate,
  });

  factory TestimonyStats.fromJson(Map<String, dynamic> json) {
    return TestimonyStats(
      userId: json['user_id'] as String?,
      totalTestimonies: json['total_testimonies'] as int? ?? 0,
      standaloneCount: json['standalone_count'] as int? ?? 0,
      gratitudeCount: json['gratitude_count'] as int? ?? 0,
      answeredPrayerCount: json['answered_prayer_count'] as int? ?? 0,
      publicCount: json['public_count'] as int? ?? 0,
      totalCelebrations: json['total_celebrations'] as int? ?? 0,
      gratitudeStreak: json['gratitude_streak'] as int? ?? 0,
      longestGratitudeStreak: json['longest_gratitude_streak'] as int? ?? 0,
      lastGratitudeDate: json['last_gratitude_date'] != null
          ? DateTime.parse(json['last_gratitude_date'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        totalTestimonies,
        gratitudeCount,
        gratitudeStreak,
      ];
}
