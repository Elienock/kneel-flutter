import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'package:quick_church/features/prayer/presentation/pages/about_page.dart';
import 'package:quick_church/features/prayer/presentation/widgets/add_prayer_bottom_sheet.dart';
import 'package:quick_church/features/prayer/presentation/widgets/daily_verse_card.dart';
import 'package:quick_church/features/prayer/presentation/widgets/empty_state.dart';
import 'package:quick_church/features/prayer/presentation/widgets/prayer_card.dart';
import 'package:quick_church/features/prayer/presentation/widgets/shimmer_loading.dart';
import 'package:quick_church/features/prayer/presentation/widgets/stats_bar.dart';

/// Dashboard page displaying prayers, stats, and daily verse.
class PrayerListPage extends StatelessWidget {
  const PrayerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.church,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('QuickChurch'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<PrayerCubit>().loadPrayers(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
        ],
      ),
      body: BlocConsumer<PrayerCubit, PrayerState>(
        listener: (context, state) {
          if (state is PrayerLoaded && state.successMessage != null) {
            _showSuccessSnackBar(context, state.successMessage!);
            context.read<PrayerCubit>().clearMessage();
          }
          if (state is PrayerError) {
            _showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          return switch (state) {
            PrayerInitial() => _buildDashboard(context, []),
            PrayerLoading() => const PrayerShimmerLoading(),
            PrayerLoaded(:final prayers) => _buildDashboard(context, prayers),
            PrayerError(:final message) => _buildErrorState(context, message),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddPrayerBottomSheet.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Prayer'),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<Prayer> prayers) {
    final activePrayers = prayers.where((p) => p.status == PrayerStatus.active).toList();

    if (prayers.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const DailyVerseCard(),
            const SizedBox(height: 24),
            EmptyStateWidget(
              onAddPrayer: () => AddPrayerBottomSheet.show(context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PrayerCubit>().loadPrayers(),
      child: CustomScrollView(
        slivers: [
          // Header section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily Verse Card
                  const DailyVerseCard(),
                  const SizedBox(height: 20),

                  // Stats Bar
                  StatsBar(prayers: prayers),
                  const SizedBox(height: 20),

                  // Section header
                  Row(
                    children: [
                      Text(
                        'Active Prayers',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          // Could navigate to "All Prayers" view
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: Text('${prayers.length} total'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Prayer list
          if (activePrayers.isEmpty)
            SliverToBoxAdapter(
              child: _buildAllAnsweredState(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final prayer = activePrayers[index];
                    return PrayerCard(
                      prayer: prayer,
                      index: index,
                      onDismissed: () {
                        context.read<PrayerCubit>().deletePrayer(prayer.id);
                      },
                    );
                  },
                  childCount: activePrayers.length,
                ),
              ),
            ),

          // Answered prayers section
          if (prayers.any((p) => p.status == PrayerStatus.answered))
            SliverToBoxAdapter(
              child: _buildAnsweredSection(context, prayers),
            ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildAnsweredSection(BuildContext context, List<Prayer> prayers) {
    final theme = Theme.of(context);
    final answeredPrayers = prayers.where((p) => p.status == PrayerStatus.answered).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Answered Prayers',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${answeredPrayers.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...answeredPrayers.take(3).map((prayer) => Opacity(
            opacity: 0.7,
            child: PrayerCard(
              prayer: prayer,
              onDismissed: () {
                context.read<PrayerCubit>().deletePrayer(prayer.id);
              },
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAllAnsweredState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Praise God!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your prayers have been answered.\nAdd new prayers to continue your journey.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<PrayerCubit>().loadPrayers(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onError, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onError),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: colorScheme.onError,
          onPressed: () => context.read<PrayerCubit>().loadPrayers(),
        ),
      ),
    );
  }
}
