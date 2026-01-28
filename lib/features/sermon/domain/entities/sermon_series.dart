import 'package:equatable/equatable.dart';

/// Represents a sermon series/folder in the Sermon Vault.
/// Maps to the 'sermon_series' table in Supabase.
class SermonSeries extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String color;
  final String icon;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SermonSeries({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.color = '#673AB7',
    this.icon = 'folder',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a SermonSeries from Supabase JSON response.
  factory SermonSeries.fromJson(Map<String, dynamic> json) {
    return SermonSeries(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#673AB7',
      icon: json['icon'] as String? ?? 'folder',
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts SermonSeries to JSON for Supabase upsert.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'color': color,
      'icon': icon,
      'sort_order': sortOrder,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Creates a new SermonSeries for insert (without id).
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'color': color,
      'icon': icon,
      'sort_order': sortOrder,
    };
  }

  SermonSeries copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? color,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SermonSeries(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        color,
        icon,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}

/// Represents a series with its note count for display.
/// Used for the "5 >" folder style in the UI.
class SermonSeriesWithCount extends Equatable {
  final SermonSeries series;
  final int noteCount;
  final DateTime? lastNoteUpdated;

  const SermonSeriesWithCount({
    required this.series,
    required this.noteCount,
    this.lastNoteUpdated,
  });

  /// Creates from Supabase view response.
  factory SermonSeriesWithCount.fromJson(Map<String, dynamic> json) {
    return SermonSeriesWithCount(
      series: SermonSeries.fromJson(json),
      noteCount: json['note_count'] as int? ?? 0,
      lastNoteUpdated: json['last_note_updated'] != null
          ? DateTime.parse(json['last_note_updated'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [series, noteCount, lastNoteUpdated];
}
