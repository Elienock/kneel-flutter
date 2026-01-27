import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'package:quick_church/features/prayer/presentation/bloc/session_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/session_state.dart';

/// Insights dashboard showing prayer statistics and activity.
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Summary
            _buildStatsSummary(context),
            const SizedBox(height: 24),

            // Prayer Heatmap
            _buildSectionHeader(context, 'Activity Heatmap'),
            const SizedBox(height: 12),
            _buildHeatmap(context),
            const SizedBox(height: 24),

            // Streak Calendar
            _buildSectionHeader(context, 'This Month'),
            const SizedBox(height: 12),
            _buildStreakCalendar(context),
            const SizedBox(height: 24),

            // Weekly Trend
            _buildSectionHeader(context, 'Weekly Trend'),
            const SizedBox(height: 12),
            _buildWeeklyChart(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    return BlocBuilder<PrayerCubit, PrayerState>(
      builder: (context, prayerState) {
        return BlocBuilder<SessionCubit, SessionState>(
          builder: (context, sessionState) {
            int totalPrayers = 0;
            int activePrayers = 0;
            int answeredPrayers = 0;
            int currentStreak = 0;

            if (prayerState is PrayerLoaded) {
              totalPrayers = prayerState.prayers.length;
              activePrayers = prayerState.prayers
                  .where((p) => p.status.name == 'active')
                  .length;
              answeredPrayers = prayerState.prayers
                  .where((p) => p.status.name == 'answered')
                  .length;
            }

            if (sessionState is SessionLoaded) {
              currentStreak = _calculateStreak(sessionState.sessions
                  .map((s) => s.startedAt)
                  .toList());
            }

            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.heart,
                    label: 'Total',
                    value: totalPrayers.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.flame,
                    label: 'Active',
                    value: activePrayers.toString(),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.checkCircle,
                    label: 'Answered',
                    value: answeredPrayers.toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.zap,
                    label: 'Streak',
                    value: '$currentStreak d',
                    color: Colors.purple,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final sortedDates = dates.toSet().map((d) => DateTime(d.year, d.month, d.day)).toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (sortedDates.isEmpty) return 0;
    if (sortedDates.first.isBefore(todayDate.subtract(const Duration(days: 1)))) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = todayDate;

    for (final date in sortedDates) {
      if (date == checkDate || date == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = date.subtract(const Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        break;
      }
    }

    return streak;
  }

  Widget _buildHeatmap(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        final activityMap = <DateTime, int>{};

        if (state is SessionLoaded) {
          for (final session in state.sessions) {
            final date = DateTime(
              session.startedAt.year,
              session.startedAt.month,
              session.startedAt.day,
            );
            activityMap[date] = (activityMap[date] ?? 0) + 1;
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha:0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heatmap grid (last 12 weeks)
              _buildHeatmapGrid(context, activityMap),
              const SizedBox(height: 12),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Less',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(5, (i) {
                    return Container(
                      margin: const EdgeInsets.only(left: 2),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha:i * 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    'More',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeatmapGrid(BuildContext context, Map<DateTime, int> activityMap) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 84)); // 12 weeks

    return SizedBox(
      height: 7 * 14.0, // 7 days * cell size
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(12, (weekIndex) {
          return Column(
            children: List.generate(7, (dayIndex) {
              final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
              final count = activityMap[DateTime(date.year, date.month, date.day)] ?? 0;
              final opacity = count == 0 ? 0.1 : (count / 5).clamp(0.2, 1.0);

              return Container(
                margin: const EdgeInsets.all(1),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: count == 0
                      ? theme.colorScheme.outline.withValues(alpha:0.1)
                      : theme.colorScheme.primary.withValues(alpha:opacity),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildStreakCalendar(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday;

    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        final activeDays = <int>{};

        if (state is SessionLoaded) {
          for (final session in state.sessions) {
            if (session.startedAt.month == now.month &&
                session.startedAt.year == now.year) {
              activeDays.add(session.startedAt.day);
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha:0.1),
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
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                              fontWeight: FontWeight.w600,
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
                      final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 2;

                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox(width: 36, height: 36);
                      }

                      final isActive = activeDays.contains(dayNumber);
                      final isToday = dayNumber == now.day;

                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : isToday
                                  ? theme.colorScheme.primary.withValues(alpha:0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isActive
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            dayNumber.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isActive
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: isToday ? FontWeight.bold : null,
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
      },
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        final weeklyData = List.filled(7, 0);

        if (state is SessionLoaded) {
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

          for (final session in state.sessions) {
            final diff = session.startedAt.difference(startOfWeek).inDays;
            if (diff >= 0 && diff < 7) {
              weeklyData[diff]++;
            }
          }
        }

        final maxValue = weeklyData.reduce((a, b) => a > b ? a : b);
        final normalizedMax = maxValue == 0 ? 1 : maxValue;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha:0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final height = (weeklyData[index] / normalizedMax) * 100;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    weeklyData[index].toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: height.clamp(4, 100),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha:0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[index],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha:0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:0.6),
            ),
          ),
        ],
      ),
    );
  }
}
