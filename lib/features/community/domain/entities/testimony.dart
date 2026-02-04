import 'friend.dart';

/// Represents a shared testimony (answered prayer) in the community.
class SharedTestimony {
  final String id;
  final Friend author;
  final String title;
  final String story;
  final DateTime answeredAt;
  final DateTime sharedAt;
  final int celebrationCount; // Like "Praise God!" reactions
  final int commentCount;
  final bool hasCelebrated; // Whether current user has celebrated

  const SharedTestimony({
    required this.id,
    required this.author,
    required this.title,
    required this.story,
    required this.answeredAt,
    required this.sharedAt,
    this.celebrationCount = 0,
    this.commentCount = 0,
    this.hasCelebrated = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(sharedAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  SharedTestimony copyWith({
    String? id,
    Friend? author,
    String? title,
    String? story,
    DateTime? answeredAt,
    DateTime? sharedAt,
    int? celebrationCount,
    int? commentCount,
    bool? hasCelebrated,
  }) {
    return SharedTestimony(
      id: id ?? this.id,
      author: author ?? this.author,
      title: title ?? this.title,
      story: story ?? this.story,
      answeredAt: answeredAt ?? this.answeredAt,
      sharedAt: sharedAt ?? this.sharedAt,
      celebrationCount: celebrationCount ?? this.celebrationCount,
      commentCount: commentCount ?? this.commentCount,
      hasCelebrated: hasCelebrated ?? this.hasCelebrated,
    );
  }
}
