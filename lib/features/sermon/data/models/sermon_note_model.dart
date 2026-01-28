import 'package:hive/hive.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';

part 'sermon_note_model.g.dart';

@HiveType(typeId: 10)
class SermonNoteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String preacher;

  @HiveField(4)
  final String mainVerse;

  @HiveField(5)
  final String? seriesTitle;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final bool isPinned;

  @HiveField(10)
  final List<String> tags;

  SermonNoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.preacher,
    required this.mainVerse,
    this.seriesTitle,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.tags = const [],
  });

  /// Convert to domain entity.
  SermonNote toEntity() {
    return SermonNote(
      id: id,
      userId: '', // Legacy Hive data doesn't have userId
      seriesId: null, // Legacy data uses seriesTitle string
      title: title,
      content: content,
      preacher: preacher,
      verse: mainVerse,
      seriesTitle: seriesTitle,
      sermonDate: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPinned: isPinned,
      tags: tags,
    );
  }

  /// Create from domain entity.
  factory SermonNoteModel.fromEntity(SermonNote entity) {
    return SermonNoteModel(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      preacher: entity.preacher,
      mainVerse: entity.verse ?? '',
      seriesTitle: entity.seriesTitle,
      date: entity.sermonDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isPinned: entity.isPinned,
      tags: entity.tags,
    );
  }
}
