import 'package:flutter/foundation.dart';

/// Centralized logger for Kneel that only prints in debug mode.
/// Replaces scattered print statements with structured logging.
class KneelLogger {
  static const String _tag = 'Kneel';

  /// Generic log message
  static void log(String message, {String? context}) {
    if (kDebugMode) {
      final prefix = context != null ? '[$_tag:$context]' : '[$_tag]';
      debugPrint('$prefix $message');
    }
  }

  /// Log info-level message
  static void info(String message, {String? context}) {
    log(message, context: context);
  }

  /// Log warning-level message
  static void warn(String message, {String? context}) {
    if (kDebugMode) {
      final prefix = context != null ? '[$_tag:$context]' : '[$_tag]';
      debugPrint('$prefix [WARN] $message');
    }
  }

  /// Log error with optional stack trace
  static void error(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$_tag:$context] ERROR: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    }
  }

  /// Firebase initialization log
  static void firebaseInitialized() {
    log('Firebase Initialized', context: 'Init');
  }

  /// Supabase connection log
  static void supabaseConnected() {
    log('Supabase Connected', context: 'Init');
  }

  /// Auth state change log
  static void authStateChanged(String? userId) {
    if (userId != null) {
      log('User signed in (UID: $userId)', context: 'Auth');
    } else {
      log('User signed out', context: 'Auth');
    }
  }

  /// Profile sync log
  static void profileSynced(String userId) {
    log('Profile synced to Supabase for user: $userId', context: 'Profile');
  }

  /// Session/lifecycle log
  static void lifecycle(String event) {
    log(event, context: 'Lifecycle');
  }

  /// Network/connectivity log
  static void network(String message) {
    log(message, context: 'Network');
  }

  /// Biometric authentication log
  static void biometric(String message) {
    log(message, context: 'Biometric');
  }
}
