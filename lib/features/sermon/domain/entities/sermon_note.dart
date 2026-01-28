import 'package:equatable/equatable.dart';

/// Represents a sermon note entry in the Sermon Vault.
/// Maps to the 'sermon_notes' table in Supabase.
class SermonNote extends Equatable {
  final String id;
  final String userId;
  final String? seriesId;
  final String title;
  final String preacher;
  final String? verse;
  final String content;
  final DateTime sermonDate;
  final bool isPinned;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data (not stored in sermon_notes table)
  final String? seriesTitle;

  const SermonNote({
    required this.id,
    required this.userId,
    this.seriesId,
    required this.title,
    required this.preacher,
    this.verse,
    required this.content,
    required this.sermonDate,
    this.isPinned = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.seriesTitle,
  });

  /// Creates a SermonNote from Supabase JSON response.
  factory SermonNote.fromJson(Map<String, dynamic> json) {
    return SermonNote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      seriesId: json['series_id'] as String?,
      title: json['title'] as String? ?? 'Untitled',
      preacher: json['preacher'] as String? ?? 'Unknown',
      verse: json['verse'] as String?,
      content: json['content'] as String? ?? '',
      sermonDate: json['sermon_date'] != null
          ? DateTime.parse(json['sermon_date'] as String)
          : DateTime.now(),
      isPinned: json['is_pinned'] as bool? ?? false,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      // Handle joined series data
      seriesTitle: json['sermon_series'] != null
          ? (json['sermon_series'] as Map<String, dynamic>)['title'] as String?
          : null,
    );
  }

  /// Converts SermonNote to JSON for Supabase upsert.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'series_id': seriesId,
      'title': title,
      'preacher': preacher,
      'verse': verse,
      'content': content,
      'sermon_date': sermonDate.toUtc().toIso8601String().split('T')[0],
      'is_pinned': isPinned,
      'tags': tags,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Creates JSON for insert (without id, lets Supabase generate UUID).
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'series_id': seriesId,
      'title': title,
      'preacher': preacher,
      'verse': verse,
      'content': content,
      'sermon_date': sermonDate.toUtc().toIso8601String().split('T')[0],
      'is_pinned': isPinned,
      'tags': tags,
    };
  }

  SermonNote copyWith({
    String? id,
    String? userId,
    String? seriesId,
    String? title,
    String? preacher,
    String? verse,
    String? content,
    DateTime? sermonDate,
    bool? isPinned,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? seriesTitle,
    bool clearSeriesId = false,
  }) {
    return SermonNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      seriesId: clearSeriesId ? null : (seriesId ?? this.seriesId),
      title: title ?? this.title,
      preacher: preacher ?? this.preacher,
      verse: verse ?? this.verse,
      content: content ?? this.content,
      sermonDate: sermonDate ?? this.sermonDate,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seriesTitle: seriesTitle ?? this.seriesTitle,
    );
  }

  /// Legacy getter for backward compatibility with existing UI.
  String get mainVerse => verse ?? '';

  /// Legacy getter for backward compatibility.
  DateTime get date => sermonDate;

  @override
  List<Object?> get props => [
        id,
        userId,
        seriesId,
        title,
        preacher,
        verse,
        content,
        sermonDate,
        isPinned,
        tags,
        createdAt,
        updatedAt,
        seriesTitle,
      ];
}

/// Represents a folder/series grouping of sermon notes for UI display.
/// This is a lightweight model for the folder list view.
class SermonFolder extends Equatable {
  final String? id; // null for "All Sermons"
  final String name;
  final int noteCount;
  final bool isAllSermons;
  final DateTime? lastUpdated;
  final String color;
  final String icon;

  const SermonFolder({
    this.id,
    required this.name,
    required this.noteCount,
    this.isAllSermons = false,
    this.lastUpdated,
    this.color = '#673AB7',
    this.icon = 'folder',
  });

  @override
  List<Object?> get props => [id, name, noteCount, isAllSermons, lastUpdated, color, icon];
}
