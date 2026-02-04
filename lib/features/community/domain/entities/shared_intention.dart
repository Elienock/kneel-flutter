import 'friend.dart';

/// Status of a shared intention.
enum IntentionStatus {
  active,
  answered,
}

/// Comment on a shared intention.
class IntentionComment {
  final String id;
  final Friend author;
  final String content;
  final DateTime createdAt;

  const IntentionComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

/// Represents a shared prayer intention/request in the community.
class SharedIntention {
  final String id;
  final Friend author;
  final String content;
  final DateTime createdAt;
  final IntentionStatus status;
  final int prayerCount;
  final int commentCount;
  final List<IntentionComment> comments;
  final bool hasPrayed; // Whether current user has prayed for this

  const SharedIntention({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.status = IntentionStatus.active,
    this.prayerCount = 0,
    this.commentCount = 0,
    this.comments = const [],
    this.hasPrayed = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  SharedIntention copyWith({
    String? id,
    Friend? author,
    String? content,
    DateTime? createdAt,
    IntentionStatus? status,
    int? prayerCount,
    int? commentCount,
    List<IntentionComment>? comments,
    bool? hasPrayed,
  }) {
    return SharedIntention(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      prayerCount: prayerCount ?? this.prayerCount,
      commentCount: commentCount ?? this.commentCount,
      comments: comments ?? this.comments,
      hasPrayed: hasPrayed ?? this.hasPrayed,
    );
  }
}
