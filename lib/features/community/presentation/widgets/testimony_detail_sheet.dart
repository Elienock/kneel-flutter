import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import '../../domain/entities/testimony.dart';
import '../../domain/entities/friend.dart';
import '../bloc/community_cubit.dart';
import '../pages/friend_profile_page.dart';

/// Bottom sheet showing full testimony details with celebration and comments.
///
/// Backend-ready structure:
/// - testimonyId used for all API calls (celebrate, comment, share)
/// - Author Friend object ready for profile navigation
/// - Comments list ready for pagination
class TestimonyDetailSheet extends StatefulWidget {
  final SharedTestimony testimony;

  const TestimonyDetailSheet({super.key, required this.testimony});

  /// Shows the testimony detail sheet.
  /// Requires CommunityCubit in the widget tree for actions.
  static Future<void> show(BuildContext context, SharedTestimony testimony) {
    // Try to get cubit if available, otherwise show without it
    CommunityCubit? cubit;
    try {
      cubit = context.read<CommunityCubit>();
    } catch (_) {
      // Cubit not available, will show read-only view
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => cubit != null
          ? BlocProvider.value(
              value: cubit,
              child: TestimonyDetailSheet(testimony: testimony),
            )
          : TestimonyDetailSheet(testimony: testimony),
    );
  }

  @override
  State<TestimonyDetailSheet> createState() => _TestimonyDetailSheetState();
}

class _TestimonyDetailSheetState extends State<TestimonyDetailSheet> {
  final _commentController = TextEditingController();
  late bool _hasCelebrated;

  // Mock comments for now - will come from backend
  final List<_TestimonyComment> _mockComments = [
    _TestimonyComment(
      author: const Friend(id: 'c1', name: 'Pastor James', bio: 'Senior Pastor'),
      content: 'Glory to God! This is such an incredible testimony of His faithfulness!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    _TestimonyComment(
      author: const Friend(id: 'c2', name: 'Mary Wilson', bio: 'Prayer warrior'),
      content: 'Praise the Lord! I was one of those praying. So happy to see this answered!',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _hasCelebrated = widget.testimony.hasCelebrated;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _celebrate() {
    if (_hasCelebrated) return;

    HapticFeedback.mediumImpact();
    setState(() => _hasCelebrated = true);

    // TODO: API call to celebrate testimony
    // context.read<CommunityCubit>().celebrateTestimony(widget.testimony.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Praise God! Your celebration has been recorded.'),
        backgroundColor: AppTheme.answeredColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareTestimony() {
    HapticFeedback.lightImpact();
    // TODO: Implement share functionality
    // Share.share('${widget.testimony.title}\n\n${widget.testimony.story}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Celebration banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.answeredColor.withAlpha(30),
                          AppTheme.goldenPromise.withAlpha(20),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.answeredColor.withAlpha(50),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.answeredColor.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.trophy,
                            color: AppTheme.answeredColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Answered Prayer',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.answeredColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.testimony.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Author info - tappable
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      FriendProfilePage.show(context, widget.testimony.author);
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primaryColor.withAlpha(25),
                          child: Text(
                            widget.testimony.author.initials,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.testimony.author.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    LucideIcons.chevronRight,
                                    size: 16,
                                    color: theme.colorScheme.outline,
                                  ),
                                ],
                              ),
                              Text(
                                'Shared ${widget.testimony.timeAgo}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Share button
                        IconButton(
                          onPressed: _shareTestimony,
                          icon: const Icon(LucideIcons.share2),
                          tooltip: 'Share Testimony',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Story
                  Text(
                    widget.testimony.story,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white.withAlpha(220) : Colors.black87,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: LucideIcons.partyPopper,
                          value: '${widget.testimony.celebrationCount + (_hasCelebrated && !widget.testimony.hasCelebrated ? 1 : 0)}',
                          label: 'Celebrating',
                          color: AppTheme.answeredColor,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: theme.colorScheme.outline.withAlpha(50),
                        ),
                        _StatItem(
                          icon: LucideIcons.messageCircle,
                          value: '${widget.testimony.commentCount}',
                          label: 'Comments',
                          color: AppTheme.secondaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Celebrate button
                  if (!_hasCelebrated)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _celebrate,
                        icon: const Icon(LucideIcons.partyPopper),
                        label: const Text('Praise God!'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.answeredColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.answeredColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.answeredColor.withAlpha(50)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.check, color: AppTheme.answeredColor),
                          const SizedBox(width: 8),
                          Text(
                            'You\'re celebrating this testimony!',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.answeredColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Comments section
                  Row(
                    children: [
                      const Icon(LucideIcons.messageCircle, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Praise & Comments',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Comment list
                  if (_mockComments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Be the first to leave a comment!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._mockComments.map((comment) => _CommentCard(
                          comment: comment,
                          isDark: isDark,
                        )),
                  const SizedBox(height: 12),

                  // Add comment
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Share your praise...',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          if (_commentController.text.trim().isNotEmpty) {
                            // TODO: API call to add comment
                            // context.read<CommunityCubit>().commentOnTestimony(
                            //   widget.testimony.id,
                            //   _commentController.text.trim(),
                            // );
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Comment feature coming soon!')),
                            );
                            _commentController.clear();
                          }
                        },
                        icon: const Icon(LucideIcons.send, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.answeredColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Comment model for testimonies (backend-ready structure)
class _TestimonyComment {
  final Friend author;
  final String content;
  final DateTime createdAt;

  const _TestimonyComment({
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

class _CommentCard extends StatelessWidget {
  final _TestimonyComment comment;
  final bool isDark;

  const _CommentCard({
    required this.comment,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.secondaryColor.withAlpha(25),
                child: Text(
                  comment.author.initials,
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                comment.author.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                comment.timeAgo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
