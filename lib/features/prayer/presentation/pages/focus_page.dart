import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'package:quick_church/features/prayer/presentation/bloc/session_cubit.dart';
import 'package:quick_church/features/prayer/presentation/widgets/prayer_detail_sheet.dart';
import 'package:quick_church/features/hall_of_faith/presentation/pages/hall_of_faith_page.dart';

/// Prayer Time tab - distraction-free prayer mode with Sacred Timer.
/// Renamed from Focus page. Now includes Active Prayers and Hall of Faith tabs.
class FocusPage extends StatefulWidget {
  /// If true, starts immediately with 1-minute quick pray session.
  final bool quickPrayMode;

  const FocusPage({super.key, this.quickPrayMode = false});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isInFocusMode = false;
  bool _isSelectingPrayers = false;
  int _selectedDuration = 5;
  int _prayersPrayed = 0;
  DateTime? _sessionStartTime;
  bool _quickPrayInitialized = false;
  Set<String> _selectedPrayerIds = {};

  // Tab controller for Active Prayers / Hall of Faith
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showPrayerSelection(List<Prayer> prayers, int durationMinutes) {
    setState(() {
      _selectedDuration = durationMinutes;
      _isSelectingPrayers = true;
      _selectedPrayerIds = prayers.map((p) => p.id).toSet();
    });
  }

  void _startFocusMode(List<Prayer> selectedPrayers) {
    setState(() {
      _isSelectingPrayers = false;
      _isInFocusMode = true;
      _prayersPrayed = 0;
      _sessionStartTime = DateTime.now();
    });
  }

  void _onSessionComplete(int actualDurationSeconds) {
    final endTime = DateTime.now();
    context.read<SessionCubit>().recordSession(
          durationSeconds: actualDurationSeconds,
          startedAt: _sessionStartTime!,
          endedAt: endTime,
          prayersPrayed: _prayersPrayed,
        );
    setState(() {
      _isInFocusMode = false;
      _sessionStartTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<PrayerCubit, PrayerState>(
      builder: (context, state) {
        final prayers = state is PrayerLoaded ? state.prayers : <Prayer>[];
        final activePrayers =
            prayers.where((p) => p.status == PrayerStatus.active).toList();

        // Auto-start quick pray mode (1 minute) if requested
        if (widget.quickPrayMode && !_quickPrayInitialized && activePrayers.isNotEmpty) {
          _quickPrayInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedDuration = 1;
              _isInFocusMode = true;
              _prayersPrayed = 0;
              _sessionStartTime = DateTime.now();
              _selectedPrayerIds = activePrayers.map((p) => p.id).toSet();
            });
          });
        }

        // Prayer Selection Screen
        if (_isSelectingPrayers) {
          return _PrayerSelectionScreen(
            prayers: activePrayers,
            selectedIds: _selectedPrayerIds,
            duration: _selectedDuration,
            onTogglePrayer: (id) {
              setState(() {
                if (_selectedPrayerIds.contains(id)) {
                  _selectedPrayerIds.remove(id);
                } else {
                  _selectedPrayerIds.add(id);
                }
              });
            },
            onSelectAll: () {
              setState(() {
                _selectedPrayerIds = activePrayers.map((p) => p.id).toSet();
              });
            },
            onDeselectAll: () {
              setState(() {
                _selectedPrayerIds.clear();
              });
            },
            onCancel: () => setState(() => _isSelectingPrayers = false),
            onStart: () {
              final selectedPrayers = activePrayers
                  .where((p) => _selectedPrayerIds.contains(p.id))
                  .toList();
              if (selectedPrayers.isNotEmpty) {
                _startFocusMode(selectedPrayers);
              }
            },
          );
        }

        // Focus Mode View
        if (_isInFocusMode) {
          final selectedPrayers = activePrayers
              .where((p) => _selectedPrayerIds.contains(p.id))
              .toList();
          return _FocusModeView(
            prayers: selectedPrayers.isNotEmpty ? selectedPrayers : activePrayers,
            currentIndex: _currentIndex,
            pageController: _pageController,
            selectedDuration: _selectedDuration,
            onExit: () => setState(() => _isInFocusMode = false),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            onPrayed: () => setState(() => _prayersPrayed++),
            onSessionComplete: _onSessionComplete,
          );
        }

        // Get answered prayers for Hall of Faith
        final answeredPrayers =
            prayers.where((p) => p.status == PrayerStatus.answered).toList();

        // Main Prayer Time Page with Tabs
        return Scaffold(
          backgroundColor:
              isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor:
                      isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                  title: Text(
                    'Prayer Time',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(56),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppTheme.primaryColor,
                        indicatorWeight: 3,
                        labelColor: isDark ? Colors.white : Colors.black87,
                        unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.heart, size: 18),
                                const SizedBox(width: 8),
                                Text('Active (${activePrayers.length})'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.trophy,
                                  size: 18,
                                  color: _selectedTabIndex == 1
                                      ? AppTheme.goldenPromise
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text('Answered (${answeredPrayers.length})'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Active Prayers Tab
                  _buildActivePrayersTab(activePrayers, isDark, theme),

                  // Hall of Faith Tab (Answered Prayers)
                  answeredPrayers.isEmpty
                      ? _EmptyAnsweredState()
                      : HallOfFaithContent(prayers: answeredPrayers),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the Active Prayers tab content.
  Widget _buildActivePrayersTab(List<Prayer> activePrayers, bool isDark, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Sacred Timer Card with Duration Selection
              _SacredTimerCard(
                prayerCount: activePrayers.length,
                onStartFocus: activePrayers.isNotEmpty
                    ? (duration) => _showPrayerSelection(activePrayers, duration)
                    : null,
              ),
              const SizedBox(height: 24),

              // Prayer Queue Preview
              if (activePrayers.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prayer Queue',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${activePrayers.length} prayers',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...activePrayers.take(5).map((prayer) => _PrayerQueueItem(
                      prayer: prayer,
                      isFirst: activePrayers.indexOf(prayer) == 0,
                    )),
                if (activePrayers.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${activePrayers.length - 5} more prayers',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ] else
                _EmptyFocusState(),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

/// Empty state for answered prayers tab.
class _EmptyAnsweredState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.goldenPromise.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.trophy,
                size: 48,
                color: AppTheme.goldenPromise.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Answered Prayers Yet',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"Keep asking, and it will be given to you"\n— Matthew 7:7',
              style: GoogleFonts.lora(
                fontSize: 15,
                color: isDark ? Colors.white54 : Colors.black45,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'When God answers a prayer, mark it as answered\nand add your testimony here.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sacred Timer card with custom duration selection.
class _SacredTimerCard extends StatefulWidget {
  final int prayerCount;
  final void Function(int duration)? onStartFocus;

  const _SacredTimerCard({
    required this.prayerCount,
    this.onStartFocus,
  });

  @override
  State<_SacredTimerCard> createState() => _SacredTimerCardState();
}

class _SacredTimerCardState extends State<_SacredTimerCard> {
  int _selectedDuration = 5;
  bool _showCustomPicker = false;
  int _customMinutes = 15;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
              : [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.timer,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.prayerCount} prayers',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Sacred Timer',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a sacred space of focused prayer',
            style: GoogleFonts.inter(
              color: Colors.white.withAlpha(179),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Duration Selection
          Text(
            'SELECT DURATION',
            style: GoogleFonts.inter(
              color: Colors.white.withAlpha(153),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Duration chips
          Row(
            children: [1, 5, 10].map((minutes) {
              final isSelected = _selectedDuration == minutes && !_showCustomPicker;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDuration = minutes;
                    _showCustomPicker = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: minutes != 10 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withAlpha(51),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$minutes',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'min',
                          style: GoogleFonts.inter(
                            color: Colors.white.withAlpha(179),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Custom duration option
          GestureDetector(
            onTap: () => setState(() {
              _showCustomPicker = true;
              _selectedDuration = _customMinutes;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _showCustomPicker
                    ? AppTheme.primaryColor
                    : Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showCustomPicker
                      ? AppTheme.primaryColor
                      : Colors.white.withAlpha(51),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.settings2,
                    color: Colors.white.withAlpha(200),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showCustomPicker ? '$_customMinutes min' : 'Custom',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom picker slider
          if (_showCustomPicker) ...[
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.primaryColor,
                inactiveTrackColor: Colors.white.withAlpha(51),
                thumbColor: Colors.white,
                overlayColor: AppTheme.primaryColor.withAlpha(51),
              ),
              child: Slider(
                value: _customMinutes.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                onChanged: (value) {
                  setState(() {
                    _customMinutes = value.round();
                    _selectedDuration = _customMinutes;
                  });
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Start Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onStartFocus != null
                  ? () => widget.onStartFocus!(_selectedDuration)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C1C1E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(LucideIcons.play),
              label: Text(
                'Select Prayers',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prayer selection screen before starting focus mode.
class _PrayerSelectionScreen extends StatelessWidget {
  final List<Prayer> prayers;
  final Set<String> selectedIds;
  final int duration;
  final void Function(String id) onTogglePrayer;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onCancel;
  final VoidCallback onStart;

  const _PrayerSelectionScreen({
    required this.prayers,
    required this.selectedIds,
    required this.duration,
    required this.onTogglePrayer,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onCancel,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: onCancel,
        ),
        title: Text(
          'Select Prayers',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: selectedIds.length == prayers.length
                ? onDeselectAll
                : onSelectAll,
            child: Text(
              selectedIds.length == prayers.length ? 'Deselect All' : 'Select All',
              style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Duration badge
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.timer,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$duration minute${duration > 1 ? 's' : ''} session',
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Prayer list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: prayers.length,
              itemBuilder: (context, index) {
                final prayer = prayers[index];
                final isSelected = selectedIds.contains(prayer.id);

                return GestureDetector(
                  onTap: () => onTogglePrayer(prayer.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : (isDark ? Colors.white38 : Colors.black26),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  LucideIcons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prayer.title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (prayer.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  prayer.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Start button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: selectedIds.isNotEmpty ? onStart : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(LucideIcons.play),
                  label: Text(
                    'Begin Prayer Time (${selectedIds.length})',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
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

/// Prayer queue item.
class _PrayerQueueItem extends StatelessWidget {
  final Prayer prayer;
  final bool isFirst;

  const _PrayerQueueItem({
    required this.prayer,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final priorityColor = switch (prayer.priority) {
      PrayerPriority.urgent => AppTheme.urgentColor,
      PrayerPriority.high => AppTheme.highColor,
      PrayerPriority.medium => AppTheme.mediumColor,
      PrayerPriority.low => AppTheme.lowColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isFirst
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 51 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirst)
                  Text(
                    'UP NEXT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                Text(
                  prayer.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isFirst)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.play,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

/// Empty state for focus mode.
class _EmptyFocusState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            LucideIcons.crosshair,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Prayers',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add prayers to enter focus mode',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen focus mode view with Sacred Timer.
class _FocusModeView extends StatefulWidget {
  final List<Prayer> prayers;
  final int currentIndex;
  final PageController pageController;
  final int selectedDuration;
  final VoidCallback onExit;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPrayed;
  final void Function(int actualDurationSeconds) onSessionComplete;

  const _FocusModeView({
    required this.prayers,
    required this.currentIndex,
    required this.pageController,
    required this.selectedDuration,
    required this.onExit,
    required this.onPageChanged,
    required this.onPrayed,
    required this.onSessionComplete,
  });

  @override
  State<_FocusModeView> createState() => _FocusModeViewState();
}

class _FocusModeViewState extends State<_FocusModeView>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late int _remainingSeconds;
  late int _totalSeconds;
  bool _isFinished = false;
  bool _isPaused = false;
  bool _showMusicOverlay = false;
  late AnimationController _pulseController;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.selectedDuration * 60;
    _remainingSeconds = _totalSeconds;
    _startTime = DateTime.now();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _startTimer();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _onTimerComplete();
          }
        });
      }
    });
  }

  void _onTimerComplete() {
    _timer.cancel();
    setState(() => _isFinished = true);
    HapticFeedback.heavyImpact();
    _pulseController.repeat(reverse: true);
  }

  void _finishSession() {
    final actualDuration = DateTime.now().difference(_startTime).inSeconds;
    widget.onSessionComplete(actualDuration);
    _exitFocusMode();
  }

  void _keepGoing() {
    setState(() {
      _isFinished = false;
      _remainingSeconds = 60;
      _totalSeconds += 60;
    });
    _pulseController.stop();
    _pulseController.reset();
    _startTimer();
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) HapticFeedback.lightImpact();
  }

  void _exitFocusMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    widget.onExit();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = 1 - (_remainingSeconds / _totalSeconds);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitConfirmation();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFFAFAFA),
        body: Stack(
          children: [
            // Prayer content with circular timer
            PageView.builder(
              controller: widget.pageController,
              itemCount: widget.prayers.length,
              onPageChanged: widget.onPageChanged,
              itemBuilder: (context, index) {
                final prayer = widget.prayers[index];
                return _SacredTimerPrayerCard(
                  prayer: prayer,
                  progress: progress,
                  remainingTime: _formatTime(_remainingSeconds),
                  isFinished: _isFinished,
                  isPaused: _isPaused,
                  pulseAnimation: _pulseController,
                );
              },
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleButton(
                        icon: LucideIcons.x,
                        onTap: _showExitConfirmation,
                        isDark: isDark,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha(26)
                              : Colors.black.withAlpha(13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.currentIndex + 1} of ${widget.prayers.length}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _CircleButton(
                            icon: LucideIcons.music,
                            onTap: () => setState(() => _showMusicOverlay = true),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _CircleButton(
                            icon: _isPaused ? LucideIcons.play : LucideIcons.pause,
                            onTap: _togglePause,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _isFinished
                      ? _buildFinishedActions(context)
                      : _buildActiveActions(context),
                ),
              ),
            ),

            // Page indicators
            Positioned(
              bottom: _isFinished ? 160 : 120,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.prayers.length > 10 ? 10 : widget.prayers.length,
                  (index) {
                    final isActive = widget.currentIndex == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primaryColor
                            : (isDark
                                ? Colors.white.withAlpha(51)
                                : Colors.black.withAlpha(26)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Music overlay
            if (_showMusicOverlay)
              _MusicOverlay(
                onClose: () => setState(() => _showMusicOverlay = false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: LucideIcons.heart,
          label: 'Prayed',
          color: const Color(0xFFFF6B6B),
          onTap: () {
            context.read<PrayerCubit>().incrementPrayerCount(
                  widget.prayers[widget.currentIndex].id,
                );
            widget.onPrayed();
            HapticFeedback.mediumImpact();
          },
        ),
        const SizedBox(width: 16),
        _ActionButton(
          icon: LucideIcons.moreHorizontal,
          label: 'More',
          color: AppTheme.primaryColor,
          onTap: () {
            HapticFeedback.selectionClick();
            // Open detail sheet for full actions including "Mark as Answered" with confirmation
            PrayerDetailSheet.show(context, widget.prayers[widget.currentIndex]);
          },
        ),
      ],
    );
  }

  Widget _buildFinishedActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Session Complete',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _keepGoing,
                icon: const Icon(LucideIcons.plus),
                label: const Text('Keep Going'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _finishSession,
                icon: const Icon(LucideIcons.check),
                label: const Text('Finish'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showExitConfirmation() {
    final actualDuration = DateTime.now().difference(_startTime).inSeconds;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'End Prayer Time?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          actualDuration >= 60
              ? 'You\'ve prayed for ${actualDuration ~/ 60} minutes. Save this session?'
              : 'You\'ve only prayed for a few seconds. Exit without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          if (actualDuration >= 60)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSessionComplete(actualDuration);
                _exitFocusMode();
              },
              child: const Text('Save & Exit'),
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exitFocusMode();
              },
              child: const Text('Exit'),
            ),
        ],
      ),
    );
  }
}

/// Sacred Timer prayer card with circular progress.
class _SacredTimerPrayerCard extends StatelessWidget {
  final Prayer prayer;
  final double progress;
  final String remainingTime;
  final bool isFinished;
  final bool isPaused;
  final AnimationController pulseAnimation;

  const _SacredTimerPrayerCard({
    required this.prayer,
    required this.progress,
    required this.remainingTime,
    required this.isFinished,
    required this.isPaused,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Timer with prayer text in center
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                final scale = isFinished ? 1.0 + (pulseAnimation.value * 0.05) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background ring
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 12,
                            backgroundColor: isDark
                                ? Colors.white.withAlpha(26)
                                : Colors.black.withAlpha(13),
                            color: Colors.transparent,
                          ),
                        ),
                        // Progress ring
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: Colors.transparent,
                            color: isFinished
                                ? AppTheme.answeredColor
                                : AppTheme.primaryColor,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // Center content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPaused)
                              const Icon(
                                LucideIcons.pause,
                                color: AppTheme.primaryColor,
                                size: 32,
                              )
                            else if (isFinished)
                              const Icon(
                                LucideIcons.check,
                                color: AppTheme.answeredColor,
                                size: 40,
                              )
                            else
                              Text(
                                remainingTime,
                                style: GoogleFonts.outfit(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            if (!isFinished && !isPaused)
                              Text(
                                'remaining',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // Priority badge
            if (prayer.priority == PrayerPriority.urgent)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.urgentColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      size: 16,
                      color: AppTheme.urgentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'URGENT',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.urgentColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

            // Prayer title
            Text(
              prayer.title,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Prayer description
            Text(
              prayer.description,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Prayer count
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.heart,
                  size: 16,
                  color: const Color(0xFFFF6B6B).withAlpha(153),
                ),
                const SizedBox(width: 6),
                Text(
                  'Prayed ${prayer.prayerCount} times',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Music overlay for Spotify/Apple Music integration.
class _MusicOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const _MusicOverlay({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withAlpha(153),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping the card
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Background Music',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: Icon(
                          LucideIcons.x,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Now playing
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(13)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.music,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Peaceful Prayer',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                'Ambient Worship',
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
                  ),
                  const SizedBox(height: 20),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => HapticFeedback.lightImpact(),
                        icon: Icon(
                          LucideIcons.skipBack,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => HapticFeedback.mediumImpact(),
                          icon: const Icon(
                            LucideIcons.play,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => HapticFeedback.lightImpact(),
                        icon: Icon(
                          LucideIcons.skipForward,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Service buttons
                  Row(
                    children: [
                      Expanded(
                        child: _MusicServiceButton(
                          label: 'Spotify',
                          color: const Color(0xFF1DB954),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Spotify integration coming soon'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MusicServiceButton(
                          label: 'Apple Music',
                          color: const Color(0xFFFA243C),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Apple Music integration coming soon'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Music service button.
class _MusicServiceButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MusicServiceButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Circle button helper widget.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(26) : Colors.black.withAlpha(13),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black87,
          size: 22,
        ),
      ),
    );
  }
}

/// Action button for focus mode.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
