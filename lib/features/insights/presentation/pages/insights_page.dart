import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/insights/domain/entities/user_session.dart';
import 'package:quick_church/features/insights/presentation/bloc/insights_cubit.dart';
import 'package:quick_church/features/insights/presentation/bloc/insights_state.dart';
import 'package:quick_church/features/insights/presentation/widgets/activity_heatmap.dart';
import 'package:quick_church/features/insights/presentation/widgets/streak_display.dart';

/// Insights dashboard showing spiritual journey statistics.
/// Features GitHub-style heatmap, streak tracking, and session stats.
class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  @override
  void initState() {
    super.initState();
    // Refresh insights when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsightsCubit>().loadInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.read<InsightsCubit>().loadInsights();
            },
          ),
        ],
      ),
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) {
          if (state is InsightsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is InsightsError) {
            return _buildErrorState(state.message, isDark);
          }

          if (state is InsightsLoaded) {
            return _buildLoadedState(state, isDark, theme);
          }

          // Initial or unknown state - show placeholder
          return _buildEmptyState(isDark);
        },
      ),
    );
  }

  Widget _buildLoadedState(InsightsLoaded state, bool isDark, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<InsightsCubit>().loadInsights();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Streak Display
            StreakDisplay(
              stats: state.streakStats,
              onTap: () => _showStreakDetails(state.streakStats),
            ).animate().fadeIn(duration: 400.ms).slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: 24),

            // Stats Grid
            _buildStatsGrid(state.streakStats, isDark)
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Activity Heatmap Section
            _buildSectionHeader(context, 'Spiritual Journey', LucideIcons.calendar),
            const SizedBox(height: 12),
            _buildHeatmapCard(state.heatmap, isDark)
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // This Month Calendar
            _buildSectionHeader(context, 'This Month', LucideIcons.calendarDays),
            const SizedBox(height: 12),
            _buildMonthCalendar(state.heatmap, isDark, theme)
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Session Type Breakdown
            _buildSectionHeader(context, 'Session Types', LucideIcons.pieChart),
            const SizedBox(height: 12),
            _buildSessionTypeBreakdown(state.recentSessions, isDark, theme)
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(StreakStats stats, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: LucideIcons.calendar,
            label: 'Sessions',
            value: '${stats.totalSessions}',
            color: AppTheme.primaryColor,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.clock,
            label: 'Minutes',
            value: _formatMinutes(stats.totalMinutes),
            color: Colors.blue,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.heart,
            label: 'Answered',
            value: '${stats.answeredPrayers}',
            color: AppTheme.secondaryColor,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '$minutes';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  Widget _buildHeatmapCard(Map<DateTime, DailyActivity> heatmap, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: ActivityHeatmap(
        activityData: heatmap,
        weeks: 16,
        onDayTap: (date, activity) => _showDayDetails(date, activity),
      ),
    );
  }

  Widget _buildMonthCalendar(
      Map<DateTime, DailyActivity> heatmap, bool isDark, ThemeData theme) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    // Get active days this month
    final activeDays = <int, DailyActivity>{};
    heatmap.forEach((date, activity) {
      if (date.month == now.month && date.year == now.year) {
        activeDays[date.day] = activity;
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(
                      width: 36,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          ...List.generate(6, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(width: 36, height: 36);
                  }

                  final activity = activeDays[dayNumber];
                  final hasActivity = activity != null;
                  final isToday = dayNumber == now.day;
                  final activityLevel = activity?.activityLevel ?? 0;

                  // Color based on activity level
                  Color? bgColor;
                  if (hasActivity) {
                    const purpleScale = [
                      Color(0xFFEDE7F6),
                      Color(0xFFD1C4E9),
                      Color(0xFFB39DDB),
                      Color(0xFF9575CD),
                      Color(0xFF673AB7),
                    ];
                    bgColor = purpleScale[activityLevel.clamp(0, 4)];
                  }

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final date = DateTime(now.year, now.month, dayNumber);
                      _showDayDetails(date, activity);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: bgColor ??
                            (isToday
                                ? AppTheme.primaryColor.withAlpha(25)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !hasActivity
                            ? Border.all(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          dayNumber.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isToday ? FontWeight.bold : null,
                            color: hasActivity && activityLevel >= 3
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSessionTypeBreakdown(
      List<UserSession> sessions, bool isDark, ThemeData theme) {
    // Count sessions by type
    final counts = <SessionType, int>{};
    for (final session in sessions) {
      counts[session.type] = (counts[session.type] ?? 0) + 1;
    }

    final total = sessions.length;

    final typeData = [
      (SessionType.prayer, LucideIcons.heart, Colors.red.shade400),
      (SessionType.bibleStudy, LucideIcons.bookOpen, Colors.blue.shade500),
      (SessionType.meditation, LucideIcons.wind, Colors.teal.shade400),
      (SessionType.sermonPrep, LucideIcons.fileText, AppTheme.primaryColor),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: typeData.map((data) {
          final type = data.$1;
          final icon = data.$2;
          final color = data.$3;
          final count = counts[type] ?? 0;
          final percentage = total > 0 ? (count / total * 100) : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type.label,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '$count sessions',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: isDark
                              ? Colors.white.withAlpha(20)
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load insights',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<InsightsCubit>().loadInsights(),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                LucideIcons.flame,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start Your Journey',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first Sacred Time session\nto begin tracking your spiritual journey.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakDetails(StreakStats stats) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      builder: (context) => _StreakDetailsSheet(stats: stats),
    );
  }

  void _showDayDetails(DateTime date, DailyActivity? activity) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _DayDetailsSheet(date: date, activity: activity),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakDetailsSheet extends StatelessWidget {
  final StreakStats stats;

  const _StreakDetailsSheet({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.flame, color: AppTheme.goldenPromise),
              const SizedBox(width: 8),
              Text(
                'Streak Details',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  label: 'Current',
                  value: '${stats.currentStreak}',
                  subtitle: stats.currentStreak == 1 ? 'day' : 'days',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'Longest',
                  value: '${stats.longestStreak}',
                  subtitle: stats.longestStreak == 1 ? 'day' : 'days',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  label: 'Total Sessions',
                  value: '${stats.totalSessions}',
                  subtitle: 'completed',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _DetailItem(
                  label: 'Total Time',
                  value: '${stats.totalMinutes ~/ 60}h ${stats.totalMinutes % 60}m',
                  subtitle: 'in prayer',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Motivational message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stats.motivationalMessage,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final bool isDark;

  const _DetailItem({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

class _DayDetailsSheet extends StatelessWidget {
  final DateTime date;
  final DailyActivity? activity;

  const _DayDetailsSheet({
    required this.date,
    this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final dateStr = '${months[date.month - 1]} ${date.day}, ${date.year}';

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Date
          Text(
            dateStr,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          if (activity != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatBubble(
                  value: '${activity!.sessionCount}',
                  label: activity!.sessionCount == 1 ? 'Session' : 'Sessions',
                  isDark: isDark,
                ),
                _StatBubble(
                  value: '${activity!.totalMinutes}',
                  label: 'Minutes',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: activity!.types.map((type) {
                return Chip(
                  label: Text(type.label),
                  avatar: Icon(
                    _getIconForType(type),
                    size: 16,
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Icon(
              LucideIcons.moon,
              size: 48,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No activity recorded',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  IconData _getIconForType(SessionType type) {
    switch (type) {
      case SessionType.prayer:
        return LucideIcons.heart;
      case SessionType.bibleStudy:
        return LucideIcons.bookOpen;
      case SessionType.meditation:
        return LucideIcons.wind;
      case SessionType.sermonPrep:
        return LucideIcons.fileText;
    }
  }
}

class _StatBubble extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _StatBubble({
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
