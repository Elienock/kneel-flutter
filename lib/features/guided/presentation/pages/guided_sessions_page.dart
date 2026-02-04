import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/guided/data/mock_guided_content.dart';
import 'package:quick_church/features/guided/domain/entities/guided_session.dart';
import 'plan_detail_page.dart';

/// YouVersion-style guided sessions library.
class GuidedSessionsPage extends StatelessWidget {
  const GuidedSessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Spiritual Growth',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),

          // Continue Section (if any in progress)
          _buildContinueSection(context, isDark),

          // Featured Plans
          _buildSectionTitle(context, 'Featured', isDark),
          _buildFeaturedPlans(context, isDark),

          // Scripture Plans
          _buildSectionTitle(context, 'Scripture & Meditation', isDark),
          _buildPlansList(context, MockGuidedPlans.getScripturePlans(), isDark),

          // Prayer Plans
          _buildSectionTitle(context, 'Guided Prayer', isDark),
          _buildPlansList(context, MockGuidedPlans.getPrayerPlans(), isDark),

          // Worship
          _buildSectionTitle(context, 'Worship', isDark),
          _buildPlansList(context, MockGuidedPlans.getWorshipPlans(), isDark),

          // Breathing
          _buildSectionTitle(context, 'Breathing & Calm', isDark),
          _buildPlansList(context, MockGuidedPlans.getBreathingPlans(), isDark),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueSection(BuildContext context, bool isDark) {
    // Find plans in progress
    final inProgress = MockGuidedPlans.getAll()
        .where((p) => p.isStarted && !p.isCompleted)
        .toList();

    if (inProgress.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Continue',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          ...inProgress.map((plan) => _ContinuePlanCard(
                plan: plan,
                isDark: isDark,
                onTap: () => _openPlan(context, plan),
              )),
        ],
      ),
    );
  }

  Widget _buildFeaturedPlans(BuildContext context, bool isDark) {
    final featured = MockGuidedPlans.getFeatured();

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: featured.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(right: index < featured.length - 1 ? 12 : 0),
              child: _FeaturedPlanCard(
                plan: featured[index],
                onTap: () => _openPlan(context, featured[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlansList(BuildContext context, List<GuidedPlan> plans, bool isDark) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(right: index < plans.length - 1 ? 12 : 0),
              child: _PlanCard(
                plan: plans[index],
                isDark: isDark,
                onTap: () => _openPlan(context, plans[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPlan(BuildContext context, GuidedPlan plan) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanDetailPage(plan: plan),
      ),
    );
  }
}

/// Featured plan card with large gradient background.
class _FeaturedPlanCard extends StatelessWidget {
  final GuidedPlan plan;
  final VoidCallback onTap;

  const _FeaturedPlanCard({
    required this.plan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [plan.gradientStart, plan.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: plan.gradientStart.withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(25),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(15),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plan.type.shortName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    plan.title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    plan.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Duration
                  Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 14,
                        color: Colors.white.withAlpha(180),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${plan.totalDays} ${plan.totalDays == 1 ? 'day' : 'days'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                    ],
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

/// Regular plan card for lists.
class _PlanCard extends StatelessWidget {
  final GuidedPlan plan;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header
            Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [plan.gradientStart, plan.gradientEnd],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  _getTypeIcon(plan.type),
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${plan.totalDays} ${plan.totalDays == 1 ? 'day' : 'days'}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
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

  IconData _getTypeIcon(GuidedContentType type) {
    switch (type) {
      case GuidedContentType.scripturePlan:
        return LucideIcons.bookOpen;
      case GuidedContentType.guidedPrayer:
        return LucideIcons.heartHandshake;
      case GuidedContentType.worshipSession:
        return LucideIcons.music;
      case GuidedContentType.breathingExercise:
        return LucideIcons.wind;
    }
  }
}

/// Continue plan card showing progress.
class _ContinuePlanCard extends StatelessWidget {
  final GuidedPlan plan;
  final bool isDark;
  final VoidCallback onTap;

  const _ContinuePlanCard({
    required this.plan,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            // Icon with gradient
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [plan.gradientStart, plan.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(LucideIcons.bookOpen, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day ${plan.completedDays + 1} of ${plan.totalDays}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: plan.progress,
                      backgroundColor: isDark ? Colors.white12 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation(plan.gradientStart),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Continue button
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: plan.gradientStart.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.play,
                color: plan.gradientStart,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
