import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/focus/domain/entities/focus_session.dart';
import 'package:quick_church/features/focus/presentation/bloc/focus_cubit.dart';
import 'package:quick_church/features/focus/presentation/bloc/focus_state.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'focus_timer_page.dart';

/// Main Focus tab page - timer setup for spiritual activities.
class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  @override
  void initState() {
    super.initState();
    context.read<FocusCubit>().loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: BlocBuilder<FocusCubit, FocusState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Focus',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set aside time for spiritual growth',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Today's Stats Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _TodayStatsCard(stats: state.stats, isDark: isDark),
                  ),
                ),

                // Section: Start a Focus Session
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Start a Session',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),

                // Focus Type Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _FocusTypeGrid(isDark: isDark),
                  ),
                ),

                // Recent Sessions
                if (state.sessions.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Sessions',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (state.sessions.length > 5)
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to full history
                              },
                              child: Text(
                                'See all',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= state.sessions.length || index >= 5) {
                          return null;
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          child: _RecentSessionCard(
                            session: state.sessions[index],
                            isDark: isDark,
                          ),
                        );
                      },
                      childCount: state.sessions.length.clamp(0, 5),
                    ),
                  ),
                ],

                // Empty state for recent sessions
                if (state.sessions.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.timer,
                              size: 48,
                              color: isDark ? Colors.white38 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No sessions yet',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start your first focus session above',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Today's stats card.
class _TodayStatsCard extends StatelessWidget {
  final FocusStats stats;
  final bool isDark;

  const _TodayStatsCard({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.timer,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Today',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (stats.currentStreak > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.flame, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.currentStreak} day streak',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.totalMinutesToday}',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'minutes today',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withAlpha(50),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.totalMinutesThisWeek}',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'minutes this week',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grid of focus type options.
class _FocusTypeGrid extends StatelessWidget {
  final bool isDark;

  const _FocusTypeGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final types = [
      FocusType.bibleStudy,
      FocusType.meditation,
      FocusType.generalPrayer,
      FocusType.specificPrayer,
      FocusType.worship,
      FocusType.journaling,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        return _FocusTypeCard(
          type: types[index],
          isDark: isDark,
          onTap: () => _startFocusSetup(context, types[index]),
        );
      },
    );
  }

  void _startFocusSetup(BuildContext context, FocusType type) {
    HapticFeedback.selectionClick();

    if (type == FocusType.specificPrayer) {
      // Show prayer picker first
      _showPrayerPicker(context);
    } else {
      // Go directly to duration picker
      _showDurationPicker(context, type, null, null);
    }
  }

  void _showPrayerPicker(BuildContext context) {
    final prayerState = context.read<PrayerCubit>().state;
    final prayers = prayerState is PrayerLoaded
        ? prayerState.prayers.where((p) => p.status == PrayerStatus.active).toList()
        : <Prayer>[];

    if (prayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active prayer requests. Add a prayer first!'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrayerPickerSheet(
        prayers: prayers,
        isDark: Theme.of(context).brightness == Brightness.dark,
        onSelect: (prayer) {
          Navigator.pop(context);
          _showDurationPicker(
            context,
            FocusType.specificPrayer,
            prayer.id,
            prayer.title,
          );
        },
      ),
    );
  }

  void _showDurationPicker(
    BuildContext context,
    FocusType type,
    String? prayerId,
    String? prayerTitle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DurationPickerSheet(
        type: type,
        prayerId: prayerId,
        prayerTitle: prayerTitle,
        isDark: Theme.of(context).brightness == Brightness.dark,
        onStart: (duration) {
          Navigator.pop(context);
          // Start the timer
          context.read<FocusCubit>().startTimer(
                type: type,
                durationMinutes: duration,
                prayerId: prayerId,
                prayerTitle: prayerTitle,
              );
          // Navigate to timer page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<FocusCubit>(),
                child: FocusTimerPage(
                  type: type,
                  prayerTitle: prayerTitle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Individual focus type card.
class _FocusTypeCard extends StatelessWidget {
  final FocusType type;
  final bool isDark;
  final VoidCallback onTap;

  const _FocusTypeCard({
    required this.type,
    required this.isDark,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (type) {
      case FocusType.bibleStudy:
        return LucideIcons.bookOpen;
      case FocusType.meditation:
        return LucideIcons.brain;
      case FocusType.generalPrayer:
        return LucideIcons.handMetal;
      case FocusType.specificPrayer:
        return LucideIcons.heartHandshake;
      case FocusType.worship:
        return LucideIcons.music;
      case FocusType.journaling:
        return LucideIcons.pencil;
    }
  }

  Color _getColor() {
    switch (type) {
      case FocusType.bibleStudy:
        return const Color(0xFF6366F1); // Indigo
      case FocusType.meditation:
        return const Color(0xFF14B8A6); // Teal
      case FocusType.generalPrayer:
        return AppTheme.primaryColor;
      case FocusType.specificPrayer:
        return const Color(0xFFEC4899); // Pink
      case FocusType.worship:
        return const Color(0xFFF59E0B); // Amber
      case FocusType.journaling:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withAlpha(50),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(isDark ? 30 : 20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(), color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Recent session card.
class _RecentSessionCard extends StatelessWidget {
  final FocusSession session;
  final bool isDark;

  const _RecentSessionCard({required this.session, required this.isDark});

  IconData _getIcon() {
    switch (session.type) {
      case FocusType.bibleStudy:
        return LucideIcons.bookOpen;
      case FocusType.meditation:
        return LucideIcons.brain;
      case FocusType.generalPrayer:
        return LucideIcons.handMetal;
      case FocusType.specificPrayer:
        return LucideIcons.heartHandshake;
      case FocusType.worship:
        return LucideIcons.music;
      case FocusType.journaling:
        return LucideIcons.pencil;
    }
  }

  Color _getColor() {
    switch (session.type) {
      case FocusType.bibleStudy:
        return const Color(0xFF6366F1);
      case FocusType.meditation:
        return const Color(0xFF14B8A6);
      case FocusType.generalPrayer:
        return AppTheme.primaryColor;
      case FocusType.specificPrayer:
        return const Color(0xFFEC4899);
      case FocusType.worship:
        return const Color(0xFFF59E0B);
      case FocusType.journaling:
        return const Color(0xFF8B5CF6);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final achievement = session.highestAchievement;

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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIcon(), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.type == FocusType.specificPrayer && session.prayerTitle != null
                            ? session.prayerTitle!
                            : session.type.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (session.isOpenEnded)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Open',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF14B8A6),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${session.actualMinutes} min • ${_formatTime(session.completedAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    if (achievement != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.trophy,
                        size: 12,
                        color: const Color(0xFFF59E0B).withAlpha(180),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (session.wasCompleted)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.answeredColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.check,
                color: AppTheme.answeredColor,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet for picking a prayer to focus on.
class _PrayerPickerSheet extends StatelessWidget {
  final List<Prayer> prayers;
  final bool isDark;
  final void Function(Prayer) onSelect;

  const _PrayerPickerSheet({
    required this.prayers,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
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
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.heartHandshake,
                    color: Color(0xFFEC4899),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a Prayer',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'Select which prayer to focus on',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Prayer list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: prayers.length,
              itemBuilder: (context, index) {
                final prayer = prayers[index];
                return ListTile(
                  onTap: () => onSelect(prayer),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.handMetal,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    prayer.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    prayer.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    color: isDark ? Colors.white38 : Colors.black26,
                    size: 20,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

/// Bottom sheet for selecting duration.
class _DurationPickerSheet extends StatefulWidget {
  final FocusType type;
  final String? prayerId;
  final String? prayerTitle;
  final bool isDark;
  final void Function(int? duration) onStart; // null = open-ended

  const _DurationPickerSheet({
    required this.type,
    this.prayerId,
    this.prayerTitle,
    required this.isDark,
    required this.onStart,
  });

  @override
  State<_DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<_DurationPickerSheet> {
  int? _selectedDuration = 15; // null = open-ended
  bool _showCustomSlider = false;
  int _customDuration = 25;

  final _presets = [5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.darkSurface : Colors.white,
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
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  widget.type.displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (widget.prayerTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${widget.prayerTitle}"',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: widget.isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'How long would you like to focus?',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: widget.isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Duration presets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                // Preset durations
                ..._presets.map((duration) {
                  final isSelected = _selectedDuration == duration && !_showCustomSlider;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedDuration = duration;
                        _showCustomSlider = false;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (widget.isDark
                                ? Colors.white.withAlpha(15)
                                : Colors.black.withAlpha(10)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '$duration min',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (widget.isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  );
                }),
                // Custom duration option
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _showCustomSlider = true;
                      _selectedDuration = _customDuration;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _showCustomSlider
                          ? AppTheme.primaryColor
                          : (widget.isDark
                              ? Colors.white.withAlpha(15)
                              : Colors.black.withAlpha(10)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _showCustomSlider
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.settings2,
                          size: 16,
                          color: _showCustomSlider
                              ? Colors.white
                              : (widget.isDark ? Colors.white70 : Colors.black54),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showCustomSlider ? '$_customDuration min' : 'Custom',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _showCustomSlider
                                ? Colors.white
                                : (widget.isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom slider
          if (_showCustomSlider) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: widget.isDark
                          ? Colors.white.withAlpha(30)
                          : Colors.black.withAlpha(20),
                      thumbColor: AppTheme.primaryColor,
                      overlayColor: AppTheme.primaryColor.withAlpha(30),
                    ),
                    child: Slider(
                      value: _customDuration.toDouble(),
                      min: 1,
                      max: 120,
                      divisions: 119,
                      onChanged: (value) {
                        setState(() {
                          _customDuration = value.round();
                          _selectedDuration = _customDuration;
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 min',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: widget.isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      Text(
                        '2 hours',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: widget.isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Open-ended option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDuration = null;
                  _showCustomSlider = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _selectedDuration == null
                      ? const Color(0xFF14B8A6).withAlpha(30)
                      : (widget.isDark
                          ? Colors.white.withAlpha(10)
                          : Colors.black.withAlpha(8)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedDuration == null
                        ? const Color(0xFF14B8A6)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.infinity,
                      size: 20,
                      color: _selectedDuration == null
                          ? const Color(0xFF14B8A6)
                          : (widget.isDark ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'No time limit',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _selectedDuration == null
                            ? const Color(0xFF14B8A6)
                            : (widget.isDark ? Colors.white54 : Colors.black45),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(I\'ll end when ready)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: widget.isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          // Start button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => widget.onStart(_selectedDuration),
                icon: const Icon(LucideIcons.play),
                label: Text(
                  _selectedDuration == null
                      ? 'Start Open Session'
                      : 'Start $_selectedDuration Minute Session',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
