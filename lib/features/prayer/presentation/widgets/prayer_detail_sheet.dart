import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/insights/presentation/bloc/insights_cubit.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/widgets/edit_prayer_bottom_sheet.dart';
import 'package:quick_church/features/prayer/presentation/widgets/pin_dialog.dart';
import 'package:quick_church/features/sacred_time/sacred_time.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_cubit.dart';
import 'package:quick_church/features/community/presentation/bloc/community_cubit.dart';

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
    // Capture ALL cubits needed for Sacred Time and Community integration
    final prayerCubit = context.read<PrayerCubit>();
    final sermonCubit = context.read<SermonCubit>();
    final insightsCubit = context.read<InsightsCubit>();
    final communityCubit = context.read<CommunityCubit>();

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
      builder: (sheetContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: prayerCubit),
          BlocProvider.value(value: sermonCubit),
          BlocProvider.value(value: insightsCubit),
          BlocProvider.value(value: communityCubit),
        ],
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
                // Log past prayer button
                IconButton(
                  icon: const Icon(LucideIcons.history),
                  tooltip: 'Log Past Prayer',
                  onPressed: () => _showLogManualPrayerDialog(context),
                ),
                // Share to Community button
                IconButton(
                  icon: const Icon(LucideIcons.users),
                  tooltip: 'Share to Community',
                  onPressed: () => _showShareToCommunityDialog(context),
                ),
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

            // Primary action: Enter Sanctuary to pray for this specific prayer
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();

                  // Launch Sacred Time with prayer context
                  // Don't pop first - let Sacred Time handle navigation
                  final completed = await SacredTime.start(
                    context,
                    prayerId: widget.prayer.id,
                    prayerTitle: widget.prayer.title,
                  );

                  // Close the detail sheet after returning from Sacred Time
                  if (mounted && completed != null) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(LucideIcons.timer),
                label: const Text('Enter Sanctuary'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary actions row
            Row(
              children: [
                // Answered/Reactivate button (now secondary, not primary)
                Expanded(
                  child: isAnswered
                      ? OutlinedButton.icon(
                          onPressed: () {
                            context.read<PrayerCubit>().markAsActive(widget.prayer.id);
                            Navigator.pop(context);
                          },
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                          label: const Text('Reactivate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.mediumColor,
                            side: const BorderSide(color: AppTheme.mediumColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => _showMarkAsAnsweredConfirmation(context),
                          icon: const Icon(LucideIcons.sparkles, size: 18),
                          label: const Text('Answered'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.answeredColor,
                            side: BorderSide(color: AppTheme.answeredColor.withAlpha(150)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Delete button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteConfirmation(context),
                    icon: Icon(LucideIcons.trash2, size: 18, color: AppTheme.urgentColor.withAlpha(180)),
                    label: Text('Delete', style: TextStyle(color: AppTheme.urgentColor.withAlpha(180))),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.urgentColor.withAlpha(100)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
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

  /// Shows dialog to log a past prayer session (for offline prayers, group prayers, etc.)
  Future<void> _showLogManualPrayerDialog(BuildContext context) async {
    final cubit = context.read<PrayerCubit>();
    int durationMinutes = 5;
    DateTime selectedDate = DateTime.now();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  LucideIcons.history,
                  color: AppTheme.secondaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text('Log Past Prayer'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Record a prayer you prayed offline, in a group, or on the go.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Duration selector
                  Text(
                    'How long did you pray?',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$durationMinutes min',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Slider(
                          value: durationMinutes.toDouble(),
                          min: 1,
                          max: 60,
                          divisions: 59,
                          activeColor: AppTheme.secondaryColor,
                          label: '$durationMinutes min',
                          onChanged: (value) {
                            setDialogState(() {
                              durationMinutes = value.round();
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('1 min', style: theme.textTheme.bodySmall),
                            Text('60 min', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date selector
                  Text(
                    'When did you pray?',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
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
                            LucideIcons.calendar,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(selectedDate),
                            style: theme.textTheme.bodyLarge,
                          ),
                          const Spacer(),
                          Icon(
                            LucideIcons.chevronDown,
                            color: theme.colorScheme.outline,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Optional notes
                  Text(
                    'Notes (optional)',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g., "Prayed during morning walk"',
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF8F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(LucideIcons.check),
                label: const Text('Log Prayer'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
      await cubit.logManualPrayer(
        prayerId: widget.prayer.id,
        durationMinutes: durationMinutes,
        prayedAt: selectedDate,
        notes: notes,
      );
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
    notesController.dispose();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Shows confirmation dialog before marking prayer as answered.
  /// This is a significant spiritual moment - not to be done casually.
  Future<void> _showMarkAsAnsweredConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.sparkles, color: AppTheme.answeredColor, size: 24),
            const SizedBox(width: 12),
            const Text('Mark as Answered?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is a moment of celebration!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your prayer "${widget.prayer.title}" will be moved to the Hall of Faith.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.prayer.prayerCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.goldenPromise.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.flame, size: 18, color: AppTheme.goldenPromise),
                    const SizedBox(width: 8),
                    Text(
                      "You've prayed for this ${widget.prayer.prayerCount} times",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.goldenPromise,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(LucideIcons.trophy, size: 18),
            label: const Text('Praise God!'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.answeredColor,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<PrayerCubit>().markAsAnswered(widget.prayer.id);
      Navigator.pop(context);
    }
  }

  /// Shows dialog to share prayer to community as a shared intention.
  Future<void> _showShareToCommunityDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.users, color: AppTheme.secondaryColor, size: 24),
            const SizedBox(width: 12),
            const Text('Share to Community'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this prayer request with your community?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.prayer.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.prayer.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.info, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your friends will be able to pray for this intention',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(LucideIcons.send, size: 18),
            label: const Text('Share'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Create the shared intention
      final content = '${widget.prayer.title}\n\n${widget.prayer.description}';
      await context.read<CommunityCubit>().createIntention(content);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prayer shared with your community!'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    }
  }

  /// Shows confirmation dialog before deleting a prayer.
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Prayer?'),
        content: Text('Are you sure you want to delete "${widget.prayer.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.urgentColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<PrayerCubit>().deletePrayer(widget.prayer.id);
      Navigator.pop(context);
    }
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
