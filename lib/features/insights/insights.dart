/// Insights Feature
///
/// Provides tracking for Sacred Time sessions, streaks,
/// and answered prayers with a GitHub-style activity heatmap.
///
/// Usage:
/// ```dart
/// // Initialize with user ID
/// insightsCubit.init(userId);
///
/// // Record a session
/// await insightsCubit.recordSession(
///   type: SessionType.prayer,
///   durationMinutes: 15,
///   actualDurationSeconds: 900,
///   completed: true,
///   prayerAnswered: false,
/// );
///
/// // Get streak stats
/// final stats = await insightsCubit.getStreakStats();
/// print('Current streak: ${stats.currentStreak} days');
/// ```
library insights;

export 'domain/entities/user_session.dart';
export 'domain/repositories/i_insights_repository.dart';
export 'data/repositories/supabase_insights_repository.dart';
export 'presentation/bloc/insights_cubit.dart';
export 'presentation/bloc/insights_state.dart';
export 'presentation/widgets/activity_heatmap.dart';
export 'presentation/widgets/streak_display.dart';
export 'presentation/widgets/streak_victory_overlay.dart';
export 'presentation/pages/insights_page.dart';
