import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/sacred_time/domain/entities/sacred_time_session.dart';

/// Configuration bottom sheet for setting up a Sacred Time session.
/// Features:
/// - Focus area chips (Prayer, Bible Study, Meditation, Sermon Prep)
/// - Cupertino-style duration picker
/// - Ambience toggle (Silence, Gentle Rain, Soft Instrumental)
class SacredTimeConfigSheet extends StatefulWidget {
  final SacredTimeConfig? initialConfig;
  final void Function(SacredTimeConfig config) onStart;

  const SacredTimeConfigSheet({
    super.key,
    this.initialConfig,
    required this.onStart,
  });

  /// Shows the configuration sheet and returns the selected config when started.
  static Future<SacredTimeConfig?> show(
    BuildContext context, {
    SacredTimeConfig? initialConfig,
  }) async {
    SacredTimeConfig? result;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SacredTimeConfigSheet(
        initialConfig: initialConfig,
        onStart: (config) {
          result = config;
          Navigator.pop(ctx);
        },
      ),
    );

    return result;
  }

  @override
  State<SacredTimeConfigSheet> createState() => _SacredTimeConfigSheetState();
}

class _SacredTimeConfigSheetState extends State<SacredTimeConfigSheet> {
  late SacredFocusArea _selectedFocus;
  late SacredDuration _selectedDuration;
  late SacredAmbience _selectedAmbience;
  late FixedExtentScrollController _durationController;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig ?? const SacredTimeConfig();
    _selectedFocus = config.focusArea;
    _selectedDuration = config.duration;
    _selectedAmbience = config.ambience;
    _durationController = FixedExtentScrollController(
      initialItem: SacredDuration.values.indexOf(_selectedDuration),
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  IconData _getFocusIcon(SacredFocusArea focus) {
    switch (focus) {
      case SacredFocusArea.prayer:
        return LucideIcons.heart;
      case SacredFocusArea.bibleStudy:
        return LucideIcons.bookOpen;
      case SacredFocusArea.meditation:
        return LucideIcons.brain;
      case SacredFocusArea.sermonPrep:
        return LucideIcons.mic2;
    }
  }

  IconData _getAmbienceIcon(SacredAmbience ambience) {
    switch (ambience) {
      case SacredAmbience.silence:
        return LucideIcons.volumeX;
      case SacredAmbience.gentleRain:
        return LucideIcons.cloudRain;
      case SacredAmbience.softInstrumental:
        return LucideIcons.music;
      case SacredAmbience.oceanWaves:
        return LucideIcons.waves;
      case SacredAmbience.cracklingFire:
        return LucideIcons.flame;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
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
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withAlpha(40),
                          AppTheme.primaryColor.withAlpha(20),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.sparkles,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sacred Time',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          'Enter your personal sanctuary',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 24),

            // Focus Area Section
            _buildSectionTitle('Focus Area', LucideIcons.target, isDark),
            const SizedBox(height: 12),
            _buildFocusAreaChips(isDark),

            const SizedBox(height: 28),

            // Duration Section
            _buildSectionTitle('Duration', LucideIcons.timer, isDark),
            const SizedBox(height: 12),
            _buildDurationPicker(isDark),

            const SizedBox(height: 28),

            // Ambience Section
            _buildSectionTitle('Ambience', LucideIcons.waves, isDark),
            const SizedBox(height: 12),
            _buildAmbienceSelector(isDark),

            const SizedBox(height: 32),

            // Start Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _onStart,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.play, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Enter Sanctuary',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms).scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1, 1),
                ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildFocusAreaChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: SacredFocusArea.values.asMap().entries.map((entry) {
          final index = entry.key;
          final focus = entry.value;
          final isSelected = _selectedFocus == focus;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFocus = focus);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white12 : Colors.grey.shade200),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withAlpha(40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFocusIcon(focus),
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      focus.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: 100 + index * 50),
              );
        }).toList(),
      ),
    );
  }

  Widget _buildDurationPicker(bool isDark) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: CupertinoPicker(
        scrollController: _durationController,
        itemExtent: 50,
        diameterRatio: 1.5,
        selectionOverlay: Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: AppTheme.primaryColor.withAlpha(80),
                width: 1.5,
              ),
            ),
          ),
        ),
        onSelectedItemChanged: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedDuration = SacredDuration.values[index];
          });
        },
        children: SacredDuration.values.map((duration) {
          final isSelected = duration == _selectedDuration;
          final isStopwatch = duration.isStopwatch;
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isStopwatch) ...[
                  Icon(
                    LucideIcons.infinity,
                    size: isSelected ? 24 : 18,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  duration.label,
                  style: GoogleFonts.outfit(
                    fontSize: isSelected ? 24 : 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 150.ms);
  }

  Widget _buildAmbienceSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: SacredAmbience.values.asMap().entries.map((entry) {
          final index = entry.key;
          final ambience = entry.value;
          final isSelected = _selectedAmbience == ambience;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index > 0 ? 8 : 0,
                right: index < SacredAmbience.values.length - 1 ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedAmbience = ambience);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withAlpha(20)
                        : (isDark ? Colors.white.withAlpha(8) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : (isDark ? Colors.white12 : Colors.grey.shade200),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAmbienceIcon(ambience),
                        size: 24,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ambience.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(
                duration: 300.ms,
                delay: Duration(milliseconds: 200 + index * 50),
              );
        }).toList(),
      ),
    );
  }

  void _onStart() {
    HapticFeedback.mediumImpact();

    // Preserve prayerId and prayerTitle from initial config
    // CRITICAL: Only link prayer if focus area is Prayer
    final shouldLinkPrayer = _selectedFocus == SacredFocusArea.prayer;

    widget.onStart(SacredTimeConfig(
      focusArea: _selectedFocus,
      duration: _selectedDuration,
      ambience: _selectedAmbience,
      // Only pass prayer context if user selected "Prayer" as focus area
      prayerId: shouldLinkPrayer ? widget.initialConfig?.prayerId : null,
      prayerTitle: shouldLinkPrayer ? widget.initialConfig?.prayerTitle : null,
    ));
  }
}
