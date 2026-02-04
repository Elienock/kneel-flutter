import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import '../../domain/entities/shared_intention.dart';
import '../bloc/community_cubit.dart';
import '../bloc/community_state.dart';
import 'intention_detail_sheet.dart';

/// Shared intentions section showing prayer requests from friends.
class SharedIntentionsSection extends StatelessWidget {
  const SharedIntentionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityCubit, CommunityState>(
      builder: (context, state) {
        if (state.intentions.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.intentions.length,
          itemBuilder: (context, index) {
            return _IntentionCard(intention: state.intentions[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                color: AppTheme.secondaryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.heart,
                size: 48,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Prayer Requests',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your friends\' prayer requests will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentionCard extends StatelessWidget {
  final SharedIntention intention;

  const _IntentionCard({required this.intention});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAnswered = intention.status == IntentionStatus.answered;

    return GestureDetector(
      onTap: () => IntentionDetailSheet.show(context, intention),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAnswered
                ? AppTheme.answeredColor.withAlpha(100)
                : theme.colorScheme.outline.withAlpha(25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withAlpha(25),
                  child: Text(
                    intention.author.initials,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        intention.author.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        intention.timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAnswered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.answeredColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 12, color: AppTheme.answeredColor),
                        const SizedBox(width: 4),
                        Text(
                          'Answered',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.answeredColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              intention.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Action row
            Row(
              children: [
                // Prayer count
                Icon(
                  intention.hasPrayed ? LucideIcons.heartHandshake : LucideIcons.heart,
                  size: 18,
                  color: intention.hasPrayed ? AppTheme.primaryColor : theme.colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  '${intention.prayerCount} praying',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: intention.hasPrayed ? AppTheme.primaryColor : theme.colorScheme.outline,
                    fontWeight: intention.hasPrayed ? FontWeight.w600 : null,
                  ),
                ),
                const SizedBox(width: 16),

                // Comment count
                const Icon(LucideIcons.messageCircle, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${intention.commentCount}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),

                const Spacer(),

                // Pray button
                if (!intention.hasPrayed && !isAnswered)
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.read<CommunityCubit>().prayForIntention(intention.id);
                    },
                    icon: const Icon(LucideIcons.heart, size: 16),
                    label: const Text('Pray'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  )
                else if (intention.hasPrayed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.check, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Prayed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
