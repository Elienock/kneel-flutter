import 'package:flutter/foundation.dart';

/// Debug logger for verifying backend connections.
/// Only prints in debug mode.
class DebugLogger {
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('[Kneel] $message');
    }
  }

  static void firebaseInitialized() {
    log('Firebase Initialized');
  }

  static void supabaseConnected() {
    log('Supabase Connected');
  }

  static void authStateChanged(String? userId) {
    if (userId != null) {
      log('Auth State: User signed in (UID: $userId)');
    } else {
      log('Auth State: User signed out');
    }
  }

  static void profileSynced(String userId) {
    log('Profile synced to Supabase for user: $userId');
  }

  static void error(String context, dynamic error) {
    log('ERROR [$context]: $error');
  }
}
