import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/widgets/edit_prayer_bottom_sheet.dart';
import 'package:quick_church/features/prayer/presentation/widgets/pin_dialog.dart';

/// Bottom sheet showing full prayer details with actions.
class PrayerDetailSheet extends StatefulWidget {
  final Prayer prayer;
  final bool isUnlocked;

  const PrayerDetailSheet({
    super.key,
    required this.prayer,
    this.isUnlocked = false,
  });

  static Future<void> show(BuildContext context, Prayer prayer, {bool isUnlocked = false}) async {
    final cubit = context.read<PrayerCubit>();

    // Check if prayer is locked and needs PIN
    if (prayer.isLocked && !isUnlocked) {
      final unlocked = await PinDialog.show(
        context,
        title: 'Unlock Prayer',
        subtitle: 'Enter PIN to view this prayer',
      );
      if (!unlocked) return;
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: PrayerDetailSheet(prayer: prayer, isUnlocked: true),
      ),
    );
  }

  @override
  State<PrayerDetailSheet> createState() => _PrayerDetailSheetState();
}

class _PrayerDetailSheetState extends State<PrayerDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final priorityColor = switch (widget.prayer.priority) {
      PrayerPriority.urgent => AppTheme.urgentColor,
      PrayerPriority.high => AppTheme.highColor,
      PrayerPriority.medium => AppTheme.mediumColor,
      PrayerPriority.low => AppTheme.lowColor,
    };

    final isAnswered = widget.prayer.status == PrayerStatus.answered;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withAlpha(77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top action row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Share button
                IconButton(
                  icon: const Icon(LucideIcons.share2),
                  tooltip: 'Share',
                  onPressed: () => _sharePrayer(context),
                ),
                // Lock/Unlock button
                IconButton(
                  icon: Icon(
                    widget.prayer.isLocked ? LucideIcons.lock : LucideIcons.unlock,
                  ),
                  tooltip: widget.prayer.isLocked ? 'Unlock' : 'Lock',
                  onPressed: () => _handleLockToggle(context),
                ),
                // Edit button
                IconButton(
                  icon: const Icon(LucideIcons.pencil),
                  tooltip: 'Edit',
                  onPressed: () {
                    Navigator.pop(context);
                    EditPrayerBottomSheet.show(context, widget.prayer);
                  },
                ),
              ],
            ),

            // Status badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isAnswered)
                  const _StatusBadge(
                    label: 'ANSWERED',
                    color: AppTheme.answeredColor,
                    icon: LucideIcons.sparkles,
                  ),
                if (widget.prayer.priority == PrayerPriority.urgent)
                  const _StatusBadge(
                    label: 'URGENT',
                    color: AppTheme.urgentColor,
                    icon: LucideIcons.alertTriangle,
                  ),
                if (widget.prayer.isLocked)
                  const _StatusBadge(
                    label: 'LOCKED',
                    color: AppTheme.primaryColor,
                    icon: LucideIcons.lock,
                  ),
                _StatusBadge(
                  label: widget.prayer.priority.name.toUpperCase(),
                  color: priorityColor,
                  icon: LucideIcons.flag,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.prayer.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                decoration: isAnswered ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              widget.prayer.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),

            // Meta info
            _MetaInfoRow(
              icon: LucideIcons.calendar,
              label: 'Created',
              value: _formatDate(widget.prayer.createdAt),
            ),
            if (widget.prayer.answeredAt != null)
              _MetaInfoRow(
                icon: LucideIcons.checkCircle,
                label: 'Answered',
                value: _formatDate(widget.prayer.answeredAt!),
              ),
            _MetaInfoRow(
              icon: LucideIcons.checkCircle2,
              label: 'Prayed',
              value: '${widget.prayer.prayerCount} times',
            ),
            if (widget.prayer.requesterName != null && widget.prayer.requesterName!.isNotEmpty)
              _MetaInfoRow(
                icon: LucideIcons.user,
                label: 'Requested by',
                value: widget.prayer.requesterName!,
              ),

            // Tags
            if (widget.prayer.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.prayer.tags.map((tag) => Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],

            // Scripture reference
            if (widget.prayer.scriptureReference != null &&
                widget.prayer.scriptureReference!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.bookOpen,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.prayer.scriptureReference!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Testimony
            if (widget.prayer.testimony != null && widget.prayer.testimony!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.answeredColor.withAlpha(13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.answeredColor.withAlpha(51),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.sparkles,
                          size: 18,
                          color: AppTheme.answeredColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'My Testimony',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.answeredColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.prayer.testimony!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.read<PrayerCubit>().incrementPrayerCount(widget.prayer.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Amen. Your prayer has been recorded.')),
                      );
                    },
                    icon: const Icon(LucideIcons.checkCircle),
                    label: const Text('Pray'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondaryColor,
                      side: const BorderSide(color: AppTheme.secondaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: isAnswered
                      ? OutlinedButton.icon(
                          onPressed: () {
                            context.read<PrayerCubit>().markAsActive(widget.prayer.id);
                            Navigator.pop(context);
                          },
                          icon: const Icon(LucideIcons.refreshCw),
                          label: const Text('Reactivate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.mediumColor,
                            side: const BorderSide(color: AppTheme.mediumColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            context.read<PrayerCubit>().markAsAnswered(widget.prayer.id);
                            Navigator.pop(context);
                          },
                          icon: const Icon(LucideIcons.sparkles),
                          label: const Text('Answered'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.answeredColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  context.read<PrayerCubit>().deletePrayer(widget.prayer.id);
                  Navigator.pop(context);
                },
                icon: const Icon(LucideIcons.trash2),
                label: const Text('Delete Prayer'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.urgentColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLockToggle(BuildContext context) async {
    if (!widget.prayer.isLocked) {
      // Locking: Check if PIN is set, if not prompt to create one
      final isPinSet = await PinManager.isPinSet();
      if (!isPinSet) {
        if (!context.mounted) return;
        final pinCreated = await PinDialog.showSetup(context);
        if (!pinCreated) return; // User cancelled PIN setup
      }
    }

    if (!context.mounted) return;
    context.read<PrayerCubit>().toggleLock(widget.prayer.id);
    Navigator.pop(context);
  }

  void _sharePrayer(BuildContext context) {
    final text = 'Prayer Request: ${widget.prayer.title}\n\n${widget.prayer.description}';
    Share.share(text, subject: 'Prayer Request: ${widget.prayer.title}');
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Status badge widget.
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Meta info row widget.
class _MetaInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
