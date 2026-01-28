import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_series.dart';

/// Abstract interface for Sermon Vault data operations.
abstract class ISermonRepository {
  // ============================================================================
  // SERIES OPERATIONS
  // ============================================================================

  /// Gets all series for a user with note counts.
  /// Returns series sorted by sort_order, with note count for "5 >" display.
  Future<List<SermonSeriesWithCount>> getSeriesWithNoteCount(String userId);

  /// Gets a single series by ID.
  Future<SermonSeries?> getSeriesById(String seriesId);

  /// Creates a new series.
  Future<SermonSeries> createSeries(SermonSeries series);

  /// Updates an existing series.
  Future<SermonSeries> updateSeries(SermonSeries series);

  /// Deletes a series. Notes in this series will have series_id set to null.
  Future<void> deleteSeries(String seriesId);

  /// Reorders series by updating sort_order.
  Future<void> reorderSeries(String userId, List<String> seriesIds);

  // ============================================================================
  // NOTES OPERATIONS
  // ============================================================================

  /// Gets all notes for a user.
  Future<List<SermonNote>> getAllNotes(String userId);

  /// Gets notes for a specific series.
  Future<List<SermonNote>> getNotesForSeries(String userId, String seriesId);

  /// Gets uncategorized notes (no series).
  Future<List<SermonNote>> getUncategorizedNotes(String userId);

  /// Gets a single note by ID.
  Future<SermonNote?> getNoteById(String noteId);

  /// Saves a note (upsert - creates if new, updates if exists).
  Future<SermonNote> saveNote(SermonNote note);

  /// Deletes a note.
  Future<void> deleteNote(String noteId);

  /// Toggles pin status.
  Future<SermonNote> togglePin(String noteId);

  // ============================================================================
  // SEARCH OPERATIONS
  // ============================================================================

  /// Global search across title, preacher, content, and verse.
  Future<List<SermonNote>> search(String userId, String query);

  // ============================================================================
  // REAL-TIME STREAMS
  // ============================================================================

  /// Stream of notes for real-time updates.
  Stream<List<SermonNote>> watchNotes(String userId);

  /// Stream of series for real-time updates.
  Stream<List<SermonSeriesWithCount>> watchSeries(String userId);
}
