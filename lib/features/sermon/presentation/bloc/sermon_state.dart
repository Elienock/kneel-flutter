import 'package:equatable/equatable.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';

abstract class SermonState extends Equatable {
  const SermonState();

  @override
  List<Object?> get props => [];
}

class SermonInitial extends SermonState {
  const SermonInitial();
}

class SermonLoading extends SermonState {
  const SermonLoading();
}

class SermonLoaded extends SermonState {
  final List<SermonNote> notes;
  final List<SermonFolder> folders;
  final String? searchQuery;
  final String? selectedFolder;

  const SermonLoaded({
    required this.notes,
    required this.folders,
    this.searchQuery,
    this.selectedFolder,
  });

  /// Get all unique series titles for the dropdown.
  List<String> get seriesTitles {
    return folders
        .where((f) => f.id != null && f.id != 'uncategorized' && !f.isAllSermons)
        .map((f) => f.name)
        .toList()
      ..sort();
  }

  /// Get notes filtered by search query (local filter for UI).
  List<SermonNote> get filteredNotes {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return notes;
    }
    final query = searchQuery!.toLowerCase();
    return notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.preacher.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          (note.seriesTitle?.toLowerCase().contains(query) ?? false) ||
          (note.verse?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Get notes for a specific folder/series.
  List<SermonNote> getNotesForFolder(String? folderName) {
    List<SermonNote> result;

    if (folderName == null || folderName == 'All Sermons') {
      result = List.from(filteredNotes);
    } else if (folderName == 'Uncategorized') {
      result = filteredNotes.where((note) => note.seriesId == null).toList();
    } else {
      // Find folder by name to get ID
      final folder = folders.firstWhere(
        (f) => f.name == folderName,
        orElse: () => const SermonFolder(name: '', noteCount: 0),
      );

      if (folder.id != null) {
        result = filteredNotes.where((note) => note.seriesId == folder.id).toList();
      } else {
        // Fallback to legacy behavior using seriesTitle
        result = filteredNotes
            .where((note) => note.seriesTitle == folderName)
            .toList();
      }
    }

    // Sort by pinned first, then by date
    result.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.sermonDate.compareTo(a.sermonDate);
    });

    return result;
  }

  /// Get folder by ID.
  SermonFolder? getFolderById(String? id) {
    if (id == null) return folders.firstWhere((f) => f.isAllSermons);
    try {
      return folders.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  SermonLoaded copyWith({
    List<SermonNote>? notes,
    List<SermonFolder>? folders,
    String? searchQuery,
    String? selectedFolder,
    bool clearSearch = false,
    bool clearFolder = false,
  }) {
    return SermonLoaded(
      notes: notes ?? this.notes,
      folders: folders ?? this.folders,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      selectedFolder: clearFolder ? null : (selectedFolder ?? this.selectedFolder),
    );
  }

  @override
  List<Object?> get props => [notes, folders, searchQuery, selectedFolder];
}

class SermonError extends SermonState {
  final String message;

  const SermonError(this.message);

  @override
  List<Object?> get props => [message];
}
