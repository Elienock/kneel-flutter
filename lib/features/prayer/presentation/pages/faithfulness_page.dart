import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';

/// Faithfulness tab showing answered prayers and testimonies.
class FaithfulnessPage extends StatelessWidget {
  const FaithfulnessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: BlocBuilder<PrayerCubit, PrayerState>(
          builder: (context, state) {
            final prayers = state is PrayerLoaded ? state.prayers : <Prayer>[];
            final answeredPrayers = prayers
                .where((p) => p.status == PrayerStatus.answered)
                .toList()
              ..sort((a, b) => (b.answeredAt ?? b.createdAt)
                  .compareTo(a.answeredAt ?? a.createdAt));

            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                  title: Text(
                    'Faithfulness',
                    style: theme.textTheme.displayMedium,
                  ),
                ),

                // Stats Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _FaithfulnessStats(
                      totalAnswered: answeredPrayers.length,
                      totalPrayers: prayers.length,
                    ),
                  ),
                ),

                // Content
                if (answeredPrayers.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final prayer = answeredPrayers[index];
                          return _AnsweredPrayerCard(
                            prayer: prayer,
                            onAddTestimony: () => _showAddTestimonyDialog(context, prayer),
                          );
                        },
                        childCount: answeredPrayers.length,
                      ),
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

  void _showAddTestimonyDialog(BuildContext context, Prayer prayer) {
    final controller = TextEditingController(text: prayer.testimony);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
                    color: theme.colorScheme.outline.withAlpha(77),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.answeredColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.answeredColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Your Testimony',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          'How did God answer this prayer?',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prayer title
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.front_hand,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prayer.title,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Testimony input
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe how God worked in this situation...',
                  alignLabelWithHint: true,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // Save button
              FilledButton(
                onPressed: () {
                  context.read<PrayerCubit>().updateTestimony(
                        prayer.id,
                        controller.text.trim(),
                      );
                  Navigator.pop(sheetContext);
                },
                child: const Text('Save Testimony'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stats card showing faithfulness metrics.
class _FaithfulnessStats extends StatelessWidget {
  final int totalAnswered;
  final int totalPrayers;

  const _FaithfulnessStats({
    required this.totalAnswered,
    required this.totalPrayers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = totalPrayers > 0
        ? ((totalAnswered / totalPrayers) * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.answeredColor,
            AppTheme.answeredColor.withAlpha(204),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.answeredColor.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.celebration,
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
                      'God\'s Faithfulness',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Track how God has answered your prayers',
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
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  value: totalAnswered.toString(),
                  label: 'Answered',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(
                child: _StatColumn(
                  value: '$percentage%',
                  label: 'Answer Rate',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(
                child: _StatColumn(
                  value: totalPrayers.toString(),
                  label: 'Total Prayers',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stat column widget.
class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withAlpha(204),
          ),
        ),
      ],
    );
  }
}

/// Empty state widget.
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.answeredColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 48,
                color: AppTheme.answeredColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Answered Prayers Yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'When God answers your prayers, mark them as answered to track His faithfulness in your life.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Answered prayer card with testimony.
class _AnsweredPrayerCard extends StatelessWidget {
  final Prayer prayer;
  final VoidCallback onAddTestimony;

  const _AnsweredPrayerCard({
    required this.prayer,
    required this.onAddTestimony,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header with answered badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.answeredColor.withAlpha(13),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.answeredColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.answeredColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (prayer.answeredAt != null)
                        Text(
                          'Answered ${_formatDate(prayer.answeredAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.answeredColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.celebration,
                  color: AppTheme.answeredColor,
                ),
              ],
            ),
          ),

          // Prayer description
          Padding(
            padding: const EdgeInsets.all(16).copyWith(top: 12),
            child: Text(
              prayer.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Testimony section
          if (prayer.testimony != null && prayer.testimony!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF8F8F8),
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
                        Icons.auto_awesome,
                        size: 16,
                        color: AppTheme.answeredColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'My Testimony',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.answeredColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prayer.testimony!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                onPressed: onAddTestimony,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Add Testimony'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.answeredColor,
                  side: const BorderSide(color: AppTheme.answeredColor),
                ),
              ),
            ),

          // Scripture reference if any
          if (prayer.scriptureReference != null &&
              prayer.scriptureReference!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    prayer.scriptureReference!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
