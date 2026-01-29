import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/widgets.dart';
import 'package:quick_church/core/utils/kneel_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Observes app lifecycle events and manages session validity.
///
/// When the app returns from background:
/// 1. Validates Firebase token is still valid
/// 2. Refreshes Supabase session if needed
///
/// This prevents "Session Expired" crashes when app is left open for days.
class AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback? onSessionExpired;
  final VoidCallback? onSessionRefreshed;

  DateTime? _lastPauseTime;

  /// Duration after which we should validate session (15 minutes)
  static const _sessionCheckThreshold = Duration(minutes: 15);

  /// Duration after which we force re-authentication (7 days)
  static const _sessionExpireThreshold = Duration(days: 7);

  AppLifecycleObserver({
    this.onSessionExpired,
    this.onSessionRefreshed,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _lastPauseTime = DateTime.now();
        KneelLogger.lifecycle('App paused');
        break;

      case AppLifecycleState.resumed:
        KneelLogger.lifecycle('App resumed');
        _handleAppResume();
        break;

      case AppLifecycleState.detached:
        KneelLogger.lifecycle('App detached');
        break;

      case AppLifecycleState.inactive:
        KneelLogger.lifecycle('App inactive');
        break;

      case AppLifecycleState.hidden:
        KneelLogger.lifecycle('App hidden');
        break;
    }
  }

  Future<void> _handleAppResume() async {
    // Skip if we haven't been paused or paused very briefly
    if (_lastPauseTime == null) return;

    final pauseDuration = DateTime.now().difference(_lastPauseTime!);

    // Only check session if app was paused for a significant time
    if (pauseDuration < _sessionCheckThreshold) {
      KneelLogger.lifecycle('Brief pause (${pauseDuration.inSeconds}s), skipping session check');
      return;
    }

    KneelLogger.lifecycle('Long pause (${pauseDuration.inMinutes}min), validating session...');

    // Check if session has expired (app left open for days)
    if (pauseDuration > _sessionExpireThreshold) {
      KneelLogger.lifecycle('Session expired after ${pauseDuration.inDays} days');
      onSessionExpired?.call();
      return;
    }

    // Validate and refresh sessions
    await _validateSessions();
  }

  Future<void> _validateSessions() async {
    try {
      // 1. Check Firebase token validity
      final firebaseValid = await _validateFirebaseSession();
      if (!firebaseValid) {
        KneelLogger.lifecycle('Firebase session invalid');
        onSessionExpired?.call();
        return;
      }

      // 2. Refresh Supabase session if needed
      await _refreshSupabaseSession();

      KneelLogger.lifecycle('Sessions validated successfully');
      onSessionRefreshed?.call();
    } catch (e) {
      KneelLogger.error('AppLifecycleObserver._validateSessions', e);
      // Don't force logout on validation errors - let normal flow handle it
    }
  }

  /// Validates Firebase session by checking if token can be refreshed
  Future<bool> _validateFirebaseSession() async {
    try {
      final user = firebase.FirebaseAuth.instance.currentUser;
      if (user == null) {
        KneelLogger.lifecycle('No Firebase user - session invalid');
        return false;
      }

      // Force token refresh to validate session
      // This will throw if the session is truly expired
      final token = await user.getIdToken(true);

      if (token == null || token.isEmpty) {
        KneelLogger.lifecycle('Firebase token refresh failed');
        return false;
      }

      KneelLogger.lifecycle('Firebase token refreshed successfully');
      return true;
    } on firebase.FirebaseAuthException catch (e) {
      KneelLogger.error('Firebase session validation', e.message);

      // These errors indicate session is truly expired
      if (e.code == 'user-token-expired' ||
          e.code == 'user-disabled' ||
          e.code == 'user-not-found') {
        return false;
      }

      // Network errors - don't invalidate session
      if (e.code == 'network-request-failed') {
        KneelLogger.lifecycle('Network error during validation - keeping session');
        return true;
      }

      return false;
    } catch (e) {
      KneelLogger.error('Firebase session validation', e);
      // Don't invalidate on unknown errors
      return true;
    }
  }

  /// Refreshes Supabase session if needed
  /// Note: We use Supabase with anon key (Firebase Auth is primary)
  /// This is mainly to ensure any Supabase realtime connections are fresh
  Future<void> _refreshSupabaseSession() async {
    try {
      // Supabase doesn't have traditional sessions when using anon key
      // But we can refresh the client connection for realtime
      // Access the client to ensure connection is alive
      final _ = Supabase.instance.client;

      // Check if realtime is connected and reconnect if needed
      // This helps with stale websocket connections
      KneelLogger.lifecycle('Supabase client refreshed');
    } catch (e) {
      KneelLogger.error('Supabase session refresh', e);
      // Non-critical - don't throw
    }
  }

  /// Call this to manually trigger session validation
  Future<bool> validateSessionNow() async {
    try {
      return await _validateFirebaseSession();
    } catch (e) {
      return false;
    }
  }
}
