import 'package:quick_church/core/utils/kneel_logger.dart';

/// Debug logger for backward compatibility.
/// @deprecated Use [KneelLogger] instead for new code.
///
/// This class redirects all calls to KneelLogger.
class DebugLogger {
  /// Generic log message
  static void log(String message) {
    KneelLogger.log(message);
  }

  /// Firebase initialization log
  static void firebaseInitialized() {
    KneelLogger.firebaseInitialized();
  }

  /// Supabase connection log
  static void supabaseConnected() {
    KneelLogger.supabaseConnected();
  }

  /// Auth state change log
  static void authStateChanged(String? userId) {
    KneelLogger.authStateChanged(userId);
  }

  /// Profile sync log
  static void profileSynced(String userId) {
    KneelLogger.profileSynced(userId);
  }

  /// Error log
  static void error(String context, dynamic error) {
    KneelLogger.error(context, error);
  }
}
