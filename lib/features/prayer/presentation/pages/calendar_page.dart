import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/presentation/bloc/session_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/session_state.dart';

/// Faithfulness Calendar page showing prayer activity with GitHub-style heatmap.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    context.read<SessionCubit>().loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: BlocBuilder<SessionCubit, SessionState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor:
                      isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                  title: Text(
                    'Faithfulness',
                    style: theme.textTheme.displayMedium,
                  ),
                ),

                // Streak Stats Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStreakHeader(context, state),
                  ),
                ),

                // Calendar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCalendar(context, state),
                  ),
                ),

                // Legend
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildLegend(context),
                  ),
                ),

                // Selected Day Details
                if (_selectedDay != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildDayDetails(context, state, _selectedDay!),
                    ),
                  ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStreakHeader(BuildContext context, SessionState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    int currentStreak = 0;
    int bestStreak = 0;
    int totalDeepSessions = 0;
    bool hasBonusStreak = false;

    if (state is SessionLoaded) {
      currentStreak = state.currentStreak;
      bestStreak = state.bestStreak;
      totalDeepSessions = state.totalDeepSessions;
      hasBonusStreak = state.hasBonusStreak;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withAlpha(204),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bonus Badge
          if (hasBonusStreak)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withAlpha(128)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.award, color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Bonus Streak Today!',
                    style: GoogleFonts.inter(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.flame,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prayer Journey',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Track your faithfulness in prayer',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  value: currentStreak.toString(),
                  label: 'Current\nStreak',
                  icon: LucideIcons.flame,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(
                child: _StatColumn(
                  value: bestStreak.toString(),
                  label: 'Best\nStreak',
                  icon: LucideIcons.trophy,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(
                child: _StatColumn(
                  value: totalDeepSessions.toString(),
                  label: 'Deep\nSessions',
                  icon: LucideIcons.sparkles,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, SessionState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          defaultTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(51),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor, width: 2),
          ),
          todayTextStyle: TextStyle(
            color: isDark ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          titleTextStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
          leftChevronIcon: Icon(
            LucideIcons.chevronLeft,
            color: isDark ? Colors.white : Colors.black,
          ),
          rightChevronIcon: Icon(
            LucideIcons.chevronRight,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(context, day, state, isSelected: false);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(context, day, state, isToday: true);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(context, day, state, isSelected: true);
          },
        ),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    SessionState state, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    bool hasActivity = false;
    bool hasDeepSession = false;

    if (state is SessionLoaded) {
      hasActivity = state.hasActivityOnDay(day);
      hasDeepSession = state.hasDeepSessionOnDay(day);
    }

    // Determine cell color based on activity
    Color? cellColor;
    Color textColor = isDark ? Colors.white : Colors.black;

    if (isSelected) {
      cellColor = AppTheme.primaryColor;
      textColor = Colors.white;
    } else if (hasDeepSession) {
      // Dark Purple for 10+ minute sessions
      cellColor = AppTheme.primaryColor;
      textColor = Colors.white;
    } else if (hasActivity) {
      // Light Purple for any prayer activity
      cellColor = AppTheme.primaryColor.withAlpha(77);
      textColor = isDark ? Colors.white : AppTheme.primaryColor;
    } else if (isToday) {
      cellColor = null; // Will show border instead
    } else {
      // Grey for no activity
      cellColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cellColor,
        shape: BoxShape.circle,
        border: isToday && !isSelected
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: isSelected || hasDeepSession ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: AppTheme.primaryColor,
          label: '10+ min',
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: AppTheme.primaryColor.withAlpha(77),
          label: 'Prayed',
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0),
          label: 'No activity',
        ),
      ],
    );
  }

  Widget _buildDayDetails(BuildContext context, SessionState state, DateTime day) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    bool hasActivity = false;
    bool hasDeepSession = false;
    int minutesPrayed = 0;

    if (state is SessionLoaded) {
      hasActivity = state.hasActivityOnDay(day);
      hasDeepSession = state.hasDeepSessionOnDay(day);
      minutesPrayed = state.getMinutesForDay(day);
    }

    final isToday = isSameDay(day, DateTime.now());
    final isFuture = day.isAfter(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDeepSession
                    ? LucideIcons.sparkles
                    : hasActivity
                        ? LucideIcons.heart
                        : LucideIcons.calendar,
                color: hasDeepSession
                    ? AppTheme.primaryColor
                    : hasActivity
                        ? AppTheme.primaryColor.withAlpha(179)
                        : theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(day),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Today',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (isFuture)
            Text(
              'This day hasn\'t arrived yet. Keep up your prayer routine!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          else if (!hasActivity)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No prayer activity recorded',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withAlpha(51)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.sunrise,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Grace is new every morning.\nStart your streak again today.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _DetailChip(
                      icon: LucideIcons.clock,
                      label: '$minutesPrayed min',
                    ),
                    const SizedBox(width: 8),
                    if (hasDeepSession)
                      _DetailChip(
                        icon: LucideIcons.sparkles,
                        label: 'Deep Session',
                        isHighlighted: true,
                      ),
                  ],
                ),
                if (hasDeepSession) ...[
                  const SizedBox(height: 8),
                  Text(
                    'You completed a deep prayer session!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

/// Stat column widget for streak header.
class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withAlpha(179), size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withAlpha(204),
          ),
        ),
      ],
    );
  }
}

/// Legend item for calendar.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Detail chip for day details.
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlighted;

  const _DetailChip({
    required this.icon,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppTheme.primaryColor.withAlpha(26)
            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F0F0)),
        borderRadius: BorderRadius.circular(20),
        border: isHighlighted
            ? Border.all(color: AppTheme.primaryColor.withAlpha(77))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isHighlighted ? AppTheme.primaryColor : null,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isHighlighted ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
