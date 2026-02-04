import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import '../../domain/entities/shared_intention.dart';
import '../bloc/community_cubit.dart';
import '../bloc/community_state.dart';
import '../widgets/intention_detail_sheet.dart';
import '../widgets/create_intention_sheet.dart';
import 'friend_profile_page.dart';

/// Full list page for all shared intentions.
class AllIntentionsPage extends StatelessWidget {
  const AllIntentionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Intentions'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: 'Share Prayer Request',
            onPressed: () {
              CreateIntentionSheet.show(context, context.read<CommunityCubit>());
            },
          ),
        ],
      ),
      body: BlocBuilder<CommunityCubit, CommunityState>(
        builder: (context, state) {
          if (state.intentions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.heart, size: 64, color: Colors.grey.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(
                    'No prayer requests yet',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share a prayer request',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      CreateIntentionSheet.show(context, context.read<CommunityCubit>());
                    },
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Share Request'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<CommunityCubit>().loadIntentions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.intentions.length,
              itemBuilder: (context, index) {
                return _IntentionCard(
                  intention: state.intentions[index],
                  isDark: isDark,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _IntentionCard extends StatelessWidget {
  final SharedIntention intention;
  final bool isDark;

  const _IntentionCard({
    required this.intention,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = intention.status == IntentionStatus.answered;

    return GestureDetector(
      onTap: () => IntentionDetailSheet.show(context, intention),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAnswered
                ? AppTheme.answeredColor.withAlpha(100)
                : AppTheme.primaryColor.withAlpha(51),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 51 : 13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row - tappable
            GestureDetector(
              onTap: () => FriendProfilePage.show(context, intention.author),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(38),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        intention.author.initials,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          intention.author.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          intention.timeAgo,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAnswered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.answeredColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.sparkles, size: 14, color: AppTheme.answeredColor),
                          const SizedBox(width: 4),
                          Text(
                            'Answered!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
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
            const SizedBox(height: 12),

            // Content
            Text(
              intention.content,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Action row
            Row(
              children: [
                Icon(
                  intention.hasPrayed ? LucideIcons.heartHandshake : LucideIcons.heart,
                  size: 16,
                  color: intention.hasPrayed ? AppTheme.primaryColor : (isDark ? Colors.white38 : Colors.black38),
                ),
                const SizedBox(width: 4),
                Text(
                  '${intention.prayerCount} praying',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: intention.hasPrayed ? AppTheme.primaryColor : (isDark ? Colors.white38 : Colors.black38),
                    fontWeight: intention.hasPrayed ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.messageCircle,
                  size: 16,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(width: 4),
                Text(
                  '${intention.commentCount}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const Spacer(),
                if (!intention.hasPrayed && !isAnswered)
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.read<CommunityCubit>().prayForIntention(intention.id);
                    },
                    icon: const Icon(LucideIcons.heart, size: 16),
                    label: const Text('Pray'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  )
                else if (intention.hasPrayed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.check, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Prayed',
                          style: GoogleFonts.inter(
                            fontSize: 13,
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
