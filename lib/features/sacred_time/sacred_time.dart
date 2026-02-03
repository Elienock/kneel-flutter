/// Sacred Time Feature
///
/// A distraction-free, timed sanctuary for prayer, Bible study,
/// meditation, and sermon preparation.
///
/// Usage:
/// ```dart
/// // Show the config sheet and start a session
/// await SacredTime.start(context, userId: user.id);
///
/// // Or show just the config sheet
/// final config = await SacredTimeConfigSheet.show(context);
/// ```
library sacred_time;

export 'domain/entities/sacred_time_session.dart';
export 'presentation/pages/sacred_time_session_page.dart';
export 'presentation/widgets/breathing_gradient.dart';
export 'presentation/widgets/sacred_time_config_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quick_church/features/insights/presentation/bloc/insights_cubit.dart';
import 'package:quick_church/features/sacred_time/domain/entities/sacred_time_session.dart';
import 'package:quick_church/features/sacred_time/presentation/pages/sacred_time_session_page.dart';
import 'package:quick_church/features/sacred_time/presentation/widgets/sacred_time_config_sheet.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_cubit.dart';

/// Helper class to easily launch Sacred Time sessions.
class SacredTime {
  SacredTime._();

  /// Shows the configuration sheet and starts a Sacred Time session.
  /// Returns true if the session was completed, false if exited early, or null if cancelled.
  ///
  /// If [prayerId] and [prayerTitle] are provided, the session will be linked
  /// to that specific prayer, and completion will increment the prayer's count.
  static Future<bool?> start(
    BuildContext context, {
    String? userId,
    SacredTimeConfig? initialConfig,
    String? prayerId,
    String? prayerTitle,
  }) async {
    HapticFeedback.selectionClick();

    // Show config sheet with prayer context if provided
    final config = await SacredTimeConfigSheet.show(
      context,
      initialConfig: initialConfig?.copyWith(
        prayerId: prayerId,
        prayerTitle: prayerTitle,
      ) ?? (prayerId != null ? SacredTimeConfig(
        focusArea: SacredFocusArea.prayer,
        duration: SacredDuration.fifteen,
        ambience: SacredAmbience.silence,
        prayerId: prayerId,
        prayerTitle: prayerTitle,
      ) : null),
    );

    if (config == null) return null;

    // Ensure prayer context is preserved if provided
    final finalConfig = (prayerId != null && config.prayerId == null)
        ? config.copyWith(prayerId: prayerId, prayerTitle: prayerTitle)
        : config;

    // Navigate to session page
    if (context.mounted) {
      return Navigator.of(context).push<bool>(
        PageRouteBuilder(
          pageBuilder: (ctx, animation, secondaryAnimation) {
            // Preserve the SermonCubit and InsightsCubit for auto-save
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<SermonCubit>()),
                BlocProvider.value(value: context.read<InsightsCubit>()),
              ],
              child: SacredTimeSessionPage(
                config: finalConfig,
                userId: userId,
              ),
            );
          },
          transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          fullscreenDialog: true,
        ),
      );
    }

    return null;
  }

  /// Quick start a session with default config (15 min prayer).
  ///
  /// If [prayerId] and [prayerTitle] are provided, the session will be linked
  /// to that specific prayer, and completion will increment the prayer's count.
  static Future<bool?> quickStart(
    BuildContext context, {
    String? userId,
    SacredFocusArea focus = SacredFocusArea.prayer,
    SacredDuration duration = SacredDuration.fifteen,
    String? prayerId,
    String? prayerTitle,
  }) async {
    HapticFeedback.mediumImpact();

    final config = SacredTimeConfig(
      focusArea: focus,
      duration: duration,
      ambience: SacredAmbience.silence,
      prayerId: prayerId,
      prayerTitle: prayerTitle,
    );

    if (context.mounted) {
      return Navigator.of(context).push<bool>(
        PageRouteBuilder(
          pageBuilder: (ctx, animation, secondaryAnimation) {
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<SermonCubit>()),
                BlocProvider.value(value: context.read<InsightsCubit>()),
              ],
              child: SacredTimeSessionPage(
                config: config,
                userId: userId,
              ),
            );
          },
          transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          fullscreenDialog: true,
        ),
      );
    }

    return null;
  }
}
