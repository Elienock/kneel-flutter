import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/guided/domain/entities/guided_session.dart';

/// Scripture/Prayer reading page with TTS-ready text layout.
class ScriptureReadingPage extends StatefulWidget {
  final GuidedPlan plan;
  final PlanDay day;

  const ScriptureReadingPage({
    super.key,
    required this.plan,
    required this.day,
  });

  @override
  State<ScriptureReadingPage> createState() => _ScriptureReadingPageState();
}

class _ScriptureReadingPageState extends State<ScriptureReadingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isPlaying = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final content = widget.day.content;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: widget.plan.gradientStart,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // TTS Play button
              IconButton(
                icon: Icon(
                  _isPlaying ? LucideIcons.pause : LucideIcons.volume2,
                  color: Colors.white,
                ),
                onPressed: _toggleTTS,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [widget.plan.gradientStart, widget.plan.gradientEnd],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.plan.totalDays > 1)
                          Text(
                            'Day ${widget.day.dayNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withAlpha(180),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          widget.day.title,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: content is ScriptureContent
                  ? _buildScriptureContent(content, isDark)
                  : content is PrayerContent
                      ? _buildPrayerContent(content, isDark)
                      : const SizedBox(),
            ),
          ),
        ],
      ),
      // Bottom action bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // TTS controls
            Expanded(
              child: FilledButton.icon(
                onPressed: _toggleTTS,
                icon: Icon(_isPlaying ? LucideIcons.pause : LucideIcons.play),
                label: Text(_isPlaying ? 'Pause' : 'Listen'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.plan.gradientStart,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Complete button
            if (!widget.day.isCompleted)
              FilledButton.icon(
                onPressed: _markComplete,
                icon: const Icon(LucideIcons.check),
                label: const Text('Complete'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.answeredColor,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.answeredColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.check, color: AppTheme.answeredColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Completed',
                      style: GoogleFonts.inter(
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
    );
  }

  Widget _buildScriptureContent(ScriptureContent content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scripture reference badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.plan.gradientStart.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content.reference,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: widget.plan.gradientStart,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Scripture text
        Container(
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Icon(
                    LucideIcons.bookOpen,
                    size: 18,
                    color: widget.plan.gradientStart,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scripture',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.plan.gradientStart,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                content.scriptureText,
                style: GoogleFonts.literata(
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.8,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Reflection
        Text(
          'Reflection',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content.reflection,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDark ? Colors.white.withAlpha(200) : Colors.black87,
            height: 1.8,
          ),
        ),

        // Prayer section
        if (content.prayer != null) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.plan.gradientStart.withAlpha(15),
                  widget.plan.gradientEnd.withAlpha(10),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.plan.gradientStart.withAlpha(50),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.heartHandshake,
                      size: 18,
                      color: widget.plan.gradientStart,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Prayer',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.plan.gradientStart,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  content.prayer!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: isDark ? Colors.white.withAlpha(200) : Colors.black87,
                    height: 1.7,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPrayerContent(PrayerContent content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Introduction
        Text(
          content.introduction,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: isDark ? Colors.white.withAlpha(200) : Colors.black87,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 32),

        // Prayer sections
        ...content.sections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section number and title
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.plan.gradientStart,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        section.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Content
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 50 : 10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    section.content,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white.withAlpha(200) : Colors.black87,
                      height: 1.7,
                    ),
                  ),
                ),
                // Prompt
                if (section.prompt != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.pencil,
                        size: 16,
                        color: widget.plan.gradientStart,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          section.prompt!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: widget.plan.gradientStart,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),

        // Closing prayer
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.plan.gradientStart.withAlpha(15),
                widget.plan.gradientEnd.withAlpha(10),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.plan.gradientStart.withAlpha(50),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.heartHandshake,
                    size: 18,
                    color: widget.plan.gradientStart,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Closing Prayer',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.plan.gradientStart,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                content.closingPrayer,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white.withAlpha(200) : Colors.black87,
                  height: 1.7,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  void _toggleTTS() {
    HapticFeedback.lightImpact();
    setState(() => _isPlaying = !_isPlaying);

    // TODO: Implement actual TTS
    // final content = widget.day.content;
    // String textToSpeak = '';
    // if (content is ScriptureContent) {
    //   textToSpeak = content.fullTextForTTS;
    // } else if (content is PrayerContent) {
    //   textToSpeak = content.fullTextForTTS;
    // }
    // FlutterTts().speak(textToSpeak);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isPlaying ? 'Text-to-speech coming soon!' : 'Paused'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _markComplete() {
    HapticFeedback.mediumImpact();
    // TODO: Save completion to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Day completed! Great job!'),
        backgroundColor: AppTheme.answeredColor,
      ),
    );
    Navigator.pop(context);
  }
}
