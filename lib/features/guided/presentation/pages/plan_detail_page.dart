import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/guided/domain/entities/guided_session.dart';
import 'package:url_launcher/url_launcher.dart';
import 'scripture_reading_page.dart';
import 'breathing_exercise_page.dart';

/// Plan detail page showing overview and day selection (YouVersion-style).
class PlanDetailPage extends StatelessWidget {
  final GuidedPlan plan;

  const PlanDetailPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header with gradient
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: plan.gradientStart,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeader(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      plan.description,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tags
                  if (plan.tags.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: plan.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: plan.gradientStart.withAlpha(25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '#$tag',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: plan.gradientStart,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Progress indicator
                  if (plan.isStarted) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildProgressSection(isDark),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Days section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      plan.totalDays == 1 ? 'Content' : 'Days',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Day cards
                  ...plan.days.map((day) => _DayCard(
                    day: day,
                    plan: plan,
                    isDark: isDark,
                    onTap: () => _openDay(context, day),
                  )),

                  // Empty state if no days
                  if (plan.days.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                LucideIcons.construction,
                                size: 48,
                                color: isDark ? Colors.white38 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Content coming soon',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Start button
      floatingActionButton: plan.days.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _startPlan(context),
              backgroundColor: plan.gradientStart,
              icon: Icon(plan.isStarted ? LucideIcons.play : LucideIcons.sparkles),
              label: Text(
                plan.isStarted ? 'Continue' : 'Start Plan',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [plan.gradientStart, plan.gradientEnd],
        ),
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      plan.type.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    plan.title,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    plan.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      _StatBadge(
                        icon: LucideIcons.calendar,
                        label: '${plan.totalDays} ${plan.totalDays == 1 ? 'day' : 'days'}',
                      ),
                      const SizedBox(width: 16),
                      if (plan.isPremium)
                        _StatBadge(
                          icon: LucideIcons.crown,
                          label: 'Premium',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: plan.progress,
                  strokeWidth: 6,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation(plan.gradientStart),
                ),
                Center(
                  child: Text(
                    '${(plan.progress * 100).round()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Progress text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Progress',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.completedDays} of ${plan.totalDays} days completed',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDay(BuildContext context, PlanDay day) {
    HapticFeedback.selectionClick();

    // Navigate based on content type
    if (day.content is ScriptureContent || day.content is PrayerContent) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScriptureReadingPage(plan: plan, day: day),
        ),
      );
    } else if (day.content is WorshipContent) {
      _showWorshipSheet(context, day.content as WorshipContent);
    } else if (day.content is BreathingContent) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BreathingExercisePage(
            plan: plan,
            content: day.content as BreathingContent,
          ),
        ),
      );
    }
  }

  void _startPlan(BuildContext context) {
    if (plan.days.isEmpty) return;

    // Find the next uncompleted day, or first day
    final nextDay = plan.days.firstWhere(
      (d) => !d.isCompleted,
      orElse: () => plan.days.first,
    );

    _openDay(context, nextDay);
  }

  void _showWorshipSheet(BuildContext context, WorshipContent content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [plan.gradientStart, plan.gradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.music, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Worship Experience',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      content.description,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Worship links
                    Text(
                      'Songs',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...content.links.map((link) => _WorshipLinkCard(
                      link: link,
                      isDark: isDark,
                    )),

                    if (content.reflectionPrompt != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: plan.gradientStart.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.pencil, color: plan.gradientStart),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                content.reflectionPrompt!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withAlpha(180)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withAlpha(180),
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final PlanDay day;
  final GuidedPlan plan;
  final bool isDark;
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.plan,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: day.isCompleted
              ? Border.all(color: plan.gradientStart.withAlpha(100), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Day number or check
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: day.isCompleted
                    ? plan.gradientStart
                    : plan.gradientStart.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: day.isCompleted
                    ? const Icon(LucideIcons.check, color: Colors.white, size: 20)
                    : Text(
                        '${day.dayNumber}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: plan.gradientStart,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.totalDays > 1 ? 'Day ${day.dayNumber}' : '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: plan.gradientStart,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    day.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              LucideIcons.chevronRight,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorshipLinkCard extends StatelessWidget {
  final WorshipLink link;
  final bool isDark;

  const _WorshipLinkCard({
    required this.link,
    required this.isDark,
  });

  IconData get _icon {
    switch (link.type) {
      case WorshipLinkType.youtube:
        return LucideIcons.youtube;
      case WorshipLinkType.spotify:
        return LucideIcons.music2;
      case WorshipLinkType.appleMusic:
        return LucideIcons.music;
      case WorshipLinkType.other:
        return LucideIcons.externalLink;
    }
  }

  Color get _color {
    switch (link.type) {
      case WorshipLinkType.youtube:
        return const Color(0xFFFF0000);
      case WorshipLinkType.spotify:
        return const Color(0xFF1DB954);
      case WorshipLinkType.appleMusic:
        return const Color(0xFFFC3C44);
      case WorshipLinkType.other:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final uri = Uri.parse(link.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(_icon, color: _color, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    link.artist,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.externalLink,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}
