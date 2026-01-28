import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quick_church/core/utils/debug_logger.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_series.dart';
import 'package:quick_church/features/sermon/domain/repositories/i_sermon_repository.dart';

/// Supabase implementation of [ISermonRepository].
@LazySingleton(as: ISermonRepository)
class SupabaseSermonRepository implements ISermonRepository {
  SupabaseClient get _client => Supabase.instance.client;

  // ============================================================================
  // SERIES OPERATIONS
  // ============================================================================

  @override
  Future<List<SermonSeriesWithCount>> getSeriesWithNoteCount(String userId) async {
    try {
      // Use raw query to get series with counts
      final response = await _client
          .from('sermon_series')
          .select('''
            *,
            sermon_notes(count)
          ''')
          .eq('user_id', userId)
          .order('sort_order', ascending: true);

      return (response as List).map((json) {
        final noteCount = json['sermon_notes'] != null
            ? (json['sermon_notes'] as List).isNotEmpty
                ? json['sermon_notes'][0]['count'] as int
                : 0
            : 0;

        return SermonSeriesWithCount(
          series: SermonSeries.fromJson(json),
          noteCount: noteCount,
          lastNoteUpdated: null, // Could add another query for this
        );
      }).toList();
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.getSeriesWithNoteCount', e);
      rethrow;
    }
  }

  @override
  Future<SermonSeries?> getSeriesById(String seriesId) async {
    try {
      final response = await _client
          .from('sermon_series')
          .select()
          .eq('id', seriesId)
          .maybeSingle();

      if (response == null) return null;
      return SermonSeries.fromJson(response);
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.getSeriesById', e);
      return null;
    }
  }

  @override
  Future<SermonSeries> createSeries(SermonSeries series) async {
    try {
      final response = await _client
          .from('sermon_series')
          .insert(series.toInsertJson())
          .select()
          .single();

      DebugLogger.log('Created series: ${response['title']}');
      return SermonSeries.fromJson(response);
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.createSeries', e);
      rethrow;
    }
  }

  @override
  Future<SermonSeries> updateSeries(SermonSeries series) async {
    try {
      final response = await _client
          .from('sermon_series')
          .update({
            'title': series.title,
            'description': series.description,
            'color': series.color,
            'icon': series.icon,
            'sort_order': series.sortOrder,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', series.id)
          .select()
          .single();

      DebugLogger.log('Updated series: ${series.id}');
      return SermonSeries.fromJson(response);
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.updateSeries', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteSeries(String seriesId) async {
    try {
      await _client.from('sermon_series').delete().eq('id', seriesId);
      DebugLogger.log('Deleted series: $seriesId');
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.deleteSeries', e);
      rethrow;
    }
  }

  @override
  Future<void> reorderSeries(String userId, List<String> seriesIds) async {
    try {
      // Update sort_order for each series
      for (int i = 0; i < seriesIds.length; i++) {
        await _client
            .from('sermon_series')
            .update({'sort_order': i})
            .eq('id', seriesIds[i])
            .eq('user_id', userId);
      }
      DebugLogger.log('Reordered ${seriesIds.length} series');
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.reorderSeries', e);
      rethrow;
    }
  }

  // ============================================================================
  // NOTES OPERATIONS
  // ============================================================================

  @override
  Future<List<SermonNote>> getAllNotes(String userId) async {
    try {
      final response = await _client
          .from('sermon_notes')
          .select('''
            *,
            sermon_series(title)
          ''')
          .eq('user_id', userId)
          .order('sermon_date', ascending: false);

      return (response as List).map((json) => SermonNote.fromJson(json)).toList();
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.getAllNotes', e);
      rethrow;
    }
  }

  @override
  Future<List<SermonNote>> getNotesForSeries(String userId, String seriesId) async {
    try {
      final response = await _client
          .from('sermon_notes')
          .select('''
            *,
            sermon_series(title)
          ''')
          .eq('user_id', userId)
          .eq('series_id', seriesId)
          .order('sermon_date', ascending: false);

      return (response as List).map((json) => SermonNote.fromJson(json)).toList();
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.getNotesForSeries', e);
      rethrow;
    }
  }

  @override
  Future<List<SermonNote>> getUncategorizedNotes(String userId) async {
    try {
      final response = await _client
          .from('sermon_notes')
          .select()
          .eq('user_id', userId)
          .isFilter('series_id', null)
          .order('sermon_date', ascending: false);

      return (response as List).map((json) => SermonNote.fromJson(json)).toList();
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.getUncategorizedNotes', e);
      rethrow;
    }
  }

  @override
  Future<SermonNote?> getNoteById(String noteId) async {
    try {
      final response = await _client
          .from('sermon_notes')
          .select('''
            *,
            sermon_series(title)
          ''')
          .eq('id', noteId)
          .maybeSingle();

      if (response == null) return null;
      return SermonNote.fromJson(response);
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.getNoteById', e);
      return null;
    }
  }

  @override
  Future<SermonNote> saveNote(SermonNote note) async {
    try {
      // Check if note has an ID (update) or not (insert)
      final isNewNote = note.id.isEmpty || note.id.startsWith('temp_');

      if (isNewNote) {
        // Insert new note
        final response = await _client
            .from('sermon_notes')
            .insert(note.toInsertJson())
            .select('''
              *,
              sermon_series(title)
            ''')
            .single();

        DebugLogger.log('Created note: ${response['title']}');
        return SermonNote.fromJson(response);
      } else {
        // Update existing note with upsert
        final response = await _client
            .from('sermon_notes')
            .upsert(note.toJson())
            .select('''
              *,
              sermon_series(title)
            ''')
            .single();

        DebugLogger.log('Updated note: ${note.id}');
        return SermonNote.fromJson(response);
      }
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.saveNote', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    try {
      await _client.from('sermon_notes').delete().eq('id', noteId);
      DebugLogger.log('Deleted note: $noteId');
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.deleteNote', e);
      rethrow;
    }
  }

  @override
  Future<SermonNote> togglePin(String noteId) async {
    try {
      // Get current pin status
      final current = await getNoteById(noteId);
      if (current == null) {
        throw Exception('Note not found');
      }

      // Toggle pin
      final response = await _client
          .from('sermon_notes')
          .update({
            'is_pinned': !current.isPinned,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', noteId)
          .select('''
            *,
            sermon_series(title)
          ''')
          .single();

      DebugLogger.log('Toggled pin for note: $noteId');
      return SermonNote.fromJson(response);
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.togglePin', e);
      rethrow;
    }
  }

  // ============================================================================
  // SEARCH OPERATIONS
  // ============================================================================

  @override
  Future<List<SermonNote>> search(String userId, String query) async {
    try {
      if (query.trim().isEmpty) {
        return getAllNotes(userId);
      }

      // Use ILIKE for case-insensitive search across multiple columns
      final searchPattern = '%$query%';

      final response = await _client
          .from('sermon_notes')
          .select('''
            *,
            sermon_series(title)
          ''')
          .eq('user_id', userId)
          .or('title.ilike.$searchPattern,preacher.ilike.$searchPattern,content.ilike.$searchPattern,verse.ilike.$searchPattern')
          .order('updated_at', ascending: false);

      DebugLogger.log('Search returned ${(response as List).length} results for "$query"');
      return response.map((json) => SermonNote.fromJson(json)).toList();
    } catch (e) {
      DebugLogger.error('SupabaseSermonRepository.search', e);
      rethrow;
    }
  }

  // ============================================================================
  // REAL-TIME STREAMS
  // ============================================================================

  @override
  Stream<List<SermonNote>> watchNotes(String userId) {
    return _client
        .from('sermon_notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('sermon_date', ascending: false)
        .map((list) => list.map((json) => SermonNote.fromJson(json)).toList());
  }

  @override
  Stream<List<SermonSeriesWithCount>> watchSeries(String userId) {
    // Note: Supabase real-time doesn't support views with counts directly
    // We use the basic stream and enrich with counts
    return _client
        .from('sermon_series')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('sort_order', ascending: true)
        .asyncMap((list) async {
          // For each series, get the note count
          final seriesWithCounts = <SermonSeriesWithCount>[];
          for (final json in list) {
            final series = SermonSeries.fromJson(json);
            final countResponse = await _client
                .from('sermon_notes')
                .select()
                .eq('series_id', series.id)
                .count(CountOption.exact);

            seriesWithCounts.add(SermonSeriesWithCount(
              series: series,
              noteCount: countResponse.count,
              lastNoteUpdated: null,
            ));
          }
          return seriesWithCounts;
        });
  }
}
