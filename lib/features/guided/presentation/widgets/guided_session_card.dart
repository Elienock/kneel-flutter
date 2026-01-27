import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/features/guided/domain/entities/guided_session.dart';

/// Card widget for displaying a guided session.
class GuidedSessionCard extends StatelessWidget {
  final GuidedSession session;
  final VoidCallback? onTap;

  const GuidedSessionCard({
    super.key,
    required this.session,
    this.onTap,
  });

  IconData _getTypeIcon() {
    switch (session.type) {
      case GuidedSessionType.scriptureMeditation:
        return LucideIcons.bookOpen;
      case GuidedSessionType.guidedPrayer:
        return LucideIcons.heartHandshake;
      case GuidedSessionType.worshipSession:
        return LucideIcons.music;
      case GuidedSessionType.breathingExercise:
        return LucideIcons.wind;
    }
  }

  Color _getTypeColor(BuildContext context) {
    switch (session.type) {
      case GuidedSessionType.scriptureMeditation:
        return Colors.indigo;
      case GuidedSessionType.guidedPrayer:
        return Colors.pink;
      case GuidedSessionType.worshipSession:
        return Colors.orange;
      case GuidedSessionType.breathingExercise:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _getTypeColor(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha:0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Premium Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: typeColor,
                    size: 22,
                  ),
                ),
                if (session.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.crown,
                          color: Colors.amber.shade700,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),

            // Title
            Text(
              session.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Duration
            Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.durationMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha:0.5),
                  ),
                ),
                const Spacer(),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha:0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
