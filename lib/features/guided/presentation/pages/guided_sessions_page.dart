import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/features/guided/data/mock_guided_content.dart';
import 'package:quick_church/features/guided/domain/entities/guided_session.dart';
import 'package:quick_church/features/guided/presentation/widgets/guided_session_card.dart';
import 'package:quick_church/features/guided/presentation/widgets/audio_player_shell.dart';

/// Page displaying the library of guided sessions.
class GuidedSessionsPage extends StatelessWidget {
  const GuidedSessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guided Sessions'),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          // Scripture Meditations
          _buildSectionHeader(context, 'Scripture Meditations', LucideIcons.bookOpen),
          _buildSessionList(
            context,
            MockGuidedContent.getByType(GuidedSessionType.scriptureMeditation),
          ),

          // Guided Prayers
          _buildSectionHeader(context, 'Guided Prayers', LucideIcons.heartHandshake),
          _buildSessionList(
            context,
            MockGuidedContent.getByType(GuidedSessionType.guidedPrayer),
          ),

          // Worship Sessions
          _buildSectionHeader(context, 'Worship Sessions', LucideIcons.music),
          _buildSessionList(
            context,
            MockGuidedContent.getByType(GuidedSessionType.worshipSession),
          ),

          // Breathing Exercises
          _buildSectionHeader(context, 'Breathing Exercises', LucideIcons.wind),
          _buildSessionList(
            context,
            MockGuidedContent.getByType(GuidedSessionType.breathingExercise),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(BuildContext context, List<GuidedSession> sessions) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(right: index < sessions.length - 1 ? 12 : 0),
              child: GuidedSessionCard(
                session: sessions[index],
                onTap: () => _showSessionDetail(context, sessions[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSessionDetail(BuildContext context, GuidedSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SessionDetailSheet(session: session),
    );
  }
}

class _SessionDetailSheet extends StatelessWidget {
  final GuidedSession session;

  const _SessionDetailSheet({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha:0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          session.type.displayName,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        session.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Duration
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 16,
                            color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${session.durationMinutes} minutes',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                            ),
                          ),
                          if (session.isPremium) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PREMIUM',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        session.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: theme.colorScheme.onSurface.withValues(alpha:0.8),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: session.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outline.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '#$tag',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Audio Player Shell
                      AudioPlayerShell(session: session),
                      const SizedBox(height: 24),

                      // Start Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: session.isPremium
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Starting: ${session.title}'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                          icon: Icon(session.isPremium ? LucideIcons.lock : LucideIcons.play),
                          label: Text(session.isPremium ? 'Unlock Premium' : 'Begin Session'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
