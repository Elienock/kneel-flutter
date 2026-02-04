import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import '../../domain/entities/testimony.dart';
import '../../domain/entities/friend.dart';
import '../widgets/testimony_detail_sheet.dart';
import 'friend_profile_page.dart';

/// Full list page for all shared testimonies.
class AllTestimoniesPage extends StatelessWidget {
  const AllTestimoniesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Mock testimonies (will come from CommunityCubit in future)
    final mockTestimonies = [
      SharedTestimony(
        id: 't1',
        author: const Friend(id: 'f1', name: 'Sarah Johnson', bio: 'Walking by faith'),
        title: 'God healed my mother!',
        story: 'After weeks of prayer, my mother\'s test results came back clear. The doctors were amazed! God is so faithful and I wanted to share this testimony with everyone who prayed for her.',
        answeredAt: DateTime.now().subtract(const Duration(days: 5)),
        sharedAt: DateTime.now().subtract(const Duration(days: 3)),
        celebrationCount: 89,
        commentCount: 23,
      ),
      SharedTestimony(
        id: 't2',
        author: const Friend(id: 'f2', name: 'Michael Chen', bio: 'Youth pastor'),
        title: 'Found the perfect job!',
        story: 'I was unemployed for 3 months and prayed every day. This community prayed with me. Last week I received an offer for my dream job! Never give up on prayer.',
        answeredAt: DateTime.now().subtract(const Duration(days: 10)),
        sharedAt: DateTime.now().subtract(const Duration(days: 7)),
        celebrationCount: 124,
        commentCount: 31,
        hasCelebrated: true,
      ),
      SharedTestimony(
        id: 't3',
        author: const Friend(id: 'f3', name: 'Grace Williams', bio: 'Music ministry'),
        title: 'Marriage restored!',
        story: 'My husband and I were on the brink of divorce. Through prayer and counseling, God has restored our marriage. We\'re celebrating our renewed vows next month!',
        answeredAt: DateTime.now().subtract(const Duration(days: 14)),
        sharedAt: DateTime.now().subtract(const Duration(days: 12)),
        celebrationCount: 156,
        commentCount: 45,
      ),
      SharedTestimony(
        id: 't4',
        author: const Friend(id: 'f4', name: 'David Miller', bio: 'Father of 3'),
        title: 'Son accepted to college!',
        story: 'We prayed for months about my son\'s college applications. He just got accepted to his first choice with a scholarship! God provides.',
        answeredAt: DateTime.now().subtract(const Duration(days: 20)),
        sharedAt: DateTime.now().subtract(const Duration(days: 18)),
        celebrationCount: 78,
        commentCount: 19,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Testimonies'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.info),
            tooltip: 'About Testimonies',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Row(
                    children: [
                      const Icon(LucideIcons.trophy, color: AppTheme.answeredColor),
                      const SizedBox(width: 8),
                      const Text('Testimonies'),
                    ],
                  ),
                  content: const Text(
                    'Testimonies are answered prayers that friends have chosen to share with the community. '
                    'Celebrate with them by tapping "Praise God!" and leave encouraging comments.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: mockTestimonies.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.trophy, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(
                    'No testimonies yet',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Answered prayers shared by friends will appear here',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mockTestimonies.length,
              itemBuilder: (context, index) {
                return _TestimonyCard(
                  testimony: mockTestimonies[index],
                  isDark: isDark,
                );
              },
            ),
    );
  }
}

class _TestimonyCard extends StatefulWidget {
  final SharedTestimony testimony;
  final bool isDark;

  const _TestimonyCard({
    required this.testimony,
    required this.isDark,
  });

  @override
  State<_TestimonyCard> createState() => _TestimonyCardState();
}

class _TestimonyCardState extends State<_TestimonyCard> {
  late bool _hasCelebrated;

  @override
  void initState() {
    super.initState();
    _hasCelebrated = widget.testimony.hasCelebrated;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        TestimonyDetailSheet.show(context, widget.testimony);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: widget.isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.answeredColor.withAlpha(100),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.answeredColor.withAlpha(25),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with celebration banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.answeredColor.withAlpha(30),
                  AppTheme.goldenPromise.withAlpha(20),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.trophy, color: AppTheme.answeredColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.testimony.title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.answeredColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Author - tappable
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: () => FriendProfilePage.show(context, widget.testimony.author),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(38),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.testimony.author.initials,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.testimony.author.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Shared ${widget.testimony.timeAgo}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: widget.isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Story
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.testimony.story,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: widget.isDark ? Colors.white70 : Colors.black87,
                height: 1.6,
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Celebration count
                Icon(
                  LucideIcons.partyPopper,
                  size: 16,
                  color: _hasCelebrated ? AppTheme.answeredColor : (widget.isDark ? Colors.white38 : Colors.black38),
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.testimony.celebrationCount + (_hasCelebrated && !widget.testimony.hasCelebrated ? 1 : 0)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _hasCelebrated ? AppTheme.answeredColor : (widget.isDark ? Colors.white38 : Colors.black38),
                    fontWeight: _hasCelebrated ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 16),
                // Comment count
                Icon(
                  LucideIcons.messageCircle,
                  size: 16,
                  color: widget.isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.testimony.commentCount}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: widget.isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const Spacer(),
                // Celebrate button
                if (!_hasCelebrated)
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _hasCelebrated = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Praise God! 🙌'),
                          backgroundColor: AppTheme.answeredColor,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.partyPopper, size: 16),
                    label: const Text('Praise God!'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.answeredColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.answeredColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.check, size: 14, color: AppTheme.answeredColor),
                        const SizedBox(width: 4),
                        Text(
                          'Celebrated',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.answeredColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
