import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quick_church/features/pulpit/domain/entities/pulpit_prayer_group.dart';

/// Repository for Pulpit Mode data operations with Supabase.
class PulpitRepository {
  final SupabaseClient _client;

  PulpitRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  // ============================================
  // PRAYER GROUPS
  // ============================================

  /// Fetch all prayer groups for the current user.
  Future<List<PulpitPrayerGroup>> getGroups() async {
    if (_userId == null) return [];

    final response = await _client
        .from('pulpit_prayer_groups')
        .select()
        .eq('user_id', _userId!)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => PulpitPrayerGroup.fromJson(json))
        .toList();
  }

  /// Fetch a single group with its prayer points.
  Future<PulpitPrayerGroup?> getGroupWithPoints(String groupId) async {
    // Fetch group
    final groupResponse = await _client
        .from('pulpit_prayer_groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();

    if (groupResponse == null) return null;

    final group = PulpitPrayerGroup.fromJson(groupResponse);

    // Fetch points
    final pointsResponse = await _client
        .from('pulpit_prayer_points')
        .select()
        .eq('group_id', groupId)
        .order('sort_order', ascending: true);

    final points = (pointsResponse as List)
        .map((json) => PulpitPrayerPoint.fromJson(json))
        .toList();

    return group.copyWith(points: points);
  }

  /// Create a new prayer group.
  Future<PulpitPrayerGroup> createGroup({
    required String title,
    String? description,
    bool autoAdvance = false,
    int secondsPerPoint = 300,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final response = await _client.from('pulpit_prayer_groups').insert({
      'user_id': _userId,
      'title': title,
      'description': description,
      'auto_advance': autoAdvance,
      'seconds_per_point': secondsPerPoint,
    }).select().single();

    return PulpitPrayerGroup.fromJson(response);
  }

  /// Update a prayer group.
  Future<PulpitPrayerGroup> updateGroup(PulpitPrayerGroup group) async {
    final response = await _client
        .from('pulpit_prayer_groups')
        .update({
          'title': group.title,
          'description': group.description,
          'auto_advance': group.autoAdvance,
          'seconds_per_point': group.secondsPerPoint,
        })
        .eq('id', group.id)
        .select()
        .single();

    return PulpitPrayerGroup.fromJson(response);
  }

  /// Delete a prayer group and all its points.
  Future<void> deleteGroup(String groupId) async {
    await _client.from('pulpit_prayer_groups').delete().eq('id', groupId);
  }

  /// Mark a group as used (increment counter, update last_used_at).
  Future<void> markGroupUsed(String groupId) async {
    await _client.rpc('increment_pulpit_usage', params: {'group_id': groupId});
  }

  /// Increment usage via direct update (fallback if RPC not available).
  Future<void> incrementGroupUsage(String groupId) async {
    // Fetch current count
    final response = await _client
        .from('pulpit_prayer_groups')
        .select('times_used')
        .eq('id', groupId)
        .single();

    final currentCount = response['times_used'] as int? ?? 0;

    await _client.from('pulpit_prayer_groups').update({
      'times_used': currentCount + 1,
      'last_used_at': DateTime.now().toIso8601String(),
    }).eq('id', groupId);
  }

  // ============================================
  // PRAYER POINTS
  // ============================================

  /// Add a prayer point to a group.
  Future<PulpitPrayerPoint> addPoint({
    required String groupId,
    required String title,
    String? description,
    List<ScriptureReference> scriptures = const [],
    int? sortOrder,
  }) async {
    // Get max sort order if not provided
    int order = sortOrder ?? 0;
    if (sortOrder == null) {
      final maxOrderResponse = await _client
          .from('pulpit_prayer_points')
          .select('sort_order')
          .eq('group_id', groupId)
          .order('sort_order', ascending: false)
          .limit(1)
          .maybeSingle();

      if (maxOrderResponse != null) {
        order = (maxOrderResponse['sort_order'] as int) + 1;
      }
    }

    final response = await _client.from('pulpit_prayer_points').insert({
      'group_id': groupId,
      'title': title,
      'description': description,
      'scriptures': scriptures.map((s) => s.toJson()).toList(),
      'sort_order': order,
    }).select().single();

    return PulpitPrayerPoint.fromJson(response);
  }

  /// Update a prayer point.
  Future<PulpitPrayerPoint> updatePoint(PulpitPrayerPoint point) async {
    final response = await _client
        .from('pulpit_prayer_points')
        .update({
          'title': point.title,
          'description': point.description,
          'scriptures': point.scriptures.map((s) => s.toJson()).toList(),
          'sort_order': point.sortOrder,
        })
        .eq('id', point.id)
        .select()
        .single();

    return PulpitPrayerPoint.fromJson(response);
  }

  /// Delete a prayer point.
  Future<void> deletePoint(String pointId) async {
    await _client.from('pulpit_prayer_points').delete().eq('id', pointId);
  }

  /// Reorder prayer points.
  Future<void> reorderPoints(List<PulpitPrayerPoint> points) async {
    // Update each point's sort_order
    for (int i = 0; i < points.length; i++) {
      await _client
          .from('pulpit_prayer_points')
          .update({'sort_order': i})
          .eq('id', points[i].id);
    }
  }

  /// Batch update sort orders (more efficient).
  Future<void> batchUpdateSortOrder(Map<String, int> pointOrders) async {
    for (final entry in pointOrders.entries) {
      await _client
          .from('pulpit_prayer_points')
          .update({'sort_order': entry.value})
          .eq('id', entry.key);
    }
  }
}
