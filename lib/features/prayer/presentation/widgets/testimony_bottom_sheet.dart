import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';

/// Bottom sheet for writing a testimony after a prayer is answered.
/// This is a celebratory moment - the UI should feel special and sacred.
class TestimonyBottomSheet extends StatefulWidget {
  final Prayer prayer;
  final VoidCallback? onComplete;

  const TestimonyBottomSheet({
    super.key,
    required this.prayer,
    this.onComplete,
  });

  /// Show the testimony sheet after marking a prayer as answered.
  static Future<void> show(BuildContext context, Prayer prayer) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TestimonyBottomSheet(
        prayer: prayer,
        onComplete: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  State<TestimonyBottomSheet> createState() => _TestimonyBottomSheetState();
}

class _TestimonyBottomSheetState extends State<TestimonyBottomSheet> {
  final _testimonyController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isPublic = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _testimonyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTestimony() async {
    if (_testimonyController.text.trim().isEmpty) {
      // Just close if no testimony written
      widget.onComplete?.call();
      return;
    }

    setState(() => _isSaving = true);

    try {
      await context.read<PrayerCubit>().updateTestimony(
        widget.prayer.id,
        _testimonyController.text.trim(),
        isPublic: _isPublic,
      );

      HapticFeedback.mediumImpact();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(_isPublic
                  ? 'Testimony shared with the community!'
                  : 'Testimony saved to your Hall of Faith'),
              ],
            ),
            backgroundColor: AppTheme.answeredColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save testimony: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Celebration header
              _buildCelebrationHeader(isDark),
              const SizedBox(height: 24),

              // Prayer info card
              _buildPrayerInfoCard(isDark),
              const SizedBox(height: 24),

              // Testimony prompt
              Text(
                'Share Your Story',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How did God answer this prayer? Your testimony can encourage others in their faith journey.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              // Testimony text field
              TextField(
                controller: _testimonyController,
                focusNode: _focusNode,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write about how God moved in this situation...',
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.answeredColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Share toggle
              _buildShareToggle(isDark),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => widget.onComplete?.call(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Skip for Now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveTestimony,
                      icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.sparkles, size: 18),
                      label: Text(_isSaving ? 'Saving...' : 'Save Testimony'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.answeredColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.answeredColor.withOpacity(0.15),
            AppTheme.goldenPromise.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.answeredColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.answeredColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.trophy,
              size: 32,
              color: AppTheme.answeredColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Prayer Answered!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.answeredColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'God is faithful!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.answeredColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.heart,
              size: 20,
              color: AppTheme.answeredColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.prayer.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.prayer.prayerCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Prayed ${widget.prayer.prayerCount} times',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.goldenPromise,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isPublic
          ? AppTheme.primaryColor.withOpacity(0.1)
          : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: _isPublic
          ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
          : null,
      ),
      child: Row(
        children: [
          Icon(
            _isPublic ? LucideIcons.globe : LucideIcons.lock,
            size: 20,
            color: _isPublic ? AppTheme.primaryColor : (isDark ? Colors.white54 : Colors.black45),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Share with Community' : 'Keep Private',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isPublic ? AppTheme.primaryColor : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPublic
                    ? 'Your testimony will encourage others'
                    : 'Only visible in your Hall of Faith',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
