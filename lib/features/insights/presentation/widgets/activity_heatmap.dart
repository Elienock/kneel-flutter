import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/insights/domain/entities/user_session.dart';

/// GitHub-style activity heatmap for visualizing spiritual journey.
/// Uses Kneel Purple color scale based on session duration.
class ActivityHeatmap extends StatefulWidget {
  final Map<DateTime, DailyActivity> activityData;
  final int weeks;
  final void Function(DateTime date, DailyActivity? activity)? onDayTap;

  const ActivityHeatmap({
    super.key,
    required this.activityData,
    this.weeks = 20,
    this.onDayTap,
  });

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  DateTime? _selectedDate;

  // Kneel Purple color scale (lightest to deepest)
  static const List<Color> _purpleScale = [
    Color(0xFFEDE7F6), // Level 0 - No activity (very light)
    Color(0xFFD1C4E9), // Level 1 - < 15 min
    Color(0xFFB39DDB), // Level 2 - 15-30 min
    Color(0xFF9575CD), // Level 3 - 30-60 min
    Color(0xFF673AB7), // Level 4 - 60+ min (Kneel Purple)
  ];

  Color _getColorForActivity(DailyActivity? activity) {
    if (activity == null) return _purpleScale[0];
    return _purpleScale[activity.activityLevel.clamp(0, 4)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: widget.weeks * 7));

    // Generate all dates for the grid
    final dates = <DateTime>[];
    var currentDate = startDate;
    while (!currentDate.isAfter(today)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Group by week
    final weeks = <List<DateTime?>>[];
    var currentWeek = <DateTime?>[];

    // Pad the first week with nulls for alignment
    final firstDayOfWeek = dates.first.weekday % 7;
    for (var i = 0; i < firstDayOfWeek; i++) {
      currentWeek.add(null);
    }

    for (final date in dates) {
      currentWeek.add(date);
      if (date.weekday == 6) {
        // Saturday
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    // Add remaining days
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels
        SizedBox(
          height: 20,
          child: Row(
            children: [
              const SizedBox(width: 32), // Space for day labels
              Expanded(
                child: _buildMonthLabels(weeks, isDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Grid with day labels
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels
            _buildDayLabels(isDark),
            const SizedBox(width: 4),

            // Heatmap grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // Start from most recent
                child: Row(
                  children: weeks.asMap().entries.map((entry) {
                    final weekIndex = entry.key;
                    final week = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Column(
                        children: week.asMap().entries.map((dayEntry) {
                          final dayIndex = dayEntry.key;
                          final date = dayEntry.value;
                          if (date == null) {
                            return _buildEmptyCell();
                          }
                          final activity = _getActivityForDate(date);
                          final isSelected = _selectedDate != null &&
                              _isSameDay(date, _selectedDate!);
                          return _buildDayCell(
                            date,
                            activity,
                            isSelected,
                            isDark,
                          ).animate().fadeIn(
                            duration: 300.ms,
                            delay: Duration(
                              milliseconds: (weekIndex * 7 + dayIndex) * 5,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Legend
        _buildLegend(isDark),

        // Selected day info
        if (_selectedDate != null)
          _buildSelectedDayInfo(isDark),
      ],
    );
  }

  Widget _buildMonthLabels(List<List<DateTime?>> weeks, bool isDark) {
    final months = <String, int>{};
    var position = 0;

    for (final week in weeks) {
      for (final date in week) {
        if (date != null && date.day <= 7) {
          final monthName = _getMonthName(date.month);
          if (!months.containsKey(monthName)) {
            months[monthName] = position;
          }
        }
      }
      position++;
    }

    return Stack(
      children: months.entries.map((entry) {
        return Positioned(
          left: entry.value * 15.0,
          child: Text(
            entry.key,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayLabels(bool isDark) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Column(
      children: days.asMap().entries.map((entry) {
        final show = entry.key % 2 == 1; // Show Mon, Wed, Fri
        return SizedBox(
          height: 15,
          width: 28,
          child: show
              ? Text(
                  entry.value,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  textAlign: TextAlign.right,
                )
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyCell() {
    return const SizedBox(width: 12, height: 12);
  }

  Widget _buildDayCell(
    DateTime date,
    DailyActivity? activity,
    bool isSelected,
    bool isDark,
  ) {
    final color = _getColorForActivity(activity);
    final isToday = _isSameDay(date, DateTime.now());

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedDate = _isSameDay(date, _selectedDate ?? DateTime(1900))
              ? null
              : date;
        });
        widget.onDayTap?.call(date, activity);
      },
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: isSelected
              ? Border.all(color: AppTheme.goldenPromise, width: 2)
              : isToday
                  ? Border.all(
                      color: isDark ? Colors.white38 : Colors.black26,
                      width: 1,
                    )
                  : null,
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Less',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        const SizedBox(width: 4),
        ..._purpleScale.map((color) {
          return Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 2),
        Text(
          'More',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayInfo(bool isDark) {
    final activity = _getActivityForDate(_selectedDate!);
    final dateStr = _formatDate(_selectedDate!);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getColorForActivity(activity),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: activity != null
                ? Text(
                    '${activity.sessionCount} session${activity.sessionCount > 1 ? 's' : ''} '
                    '(${activity.totalMinutes} min) on $dateStr',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  )
                : Text(
                    'No activity on $dateStr',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  DailyActivity? _getActivityForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return widget.activityData[normalizedDate];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }
}
