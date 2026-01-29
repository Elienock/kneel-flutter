import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_church/core/theme/app_theme.dart';

/// Centralized SnackBar manager for consistent, user-friendly error messages.
/// Translates technical error messages into human-readable form.
class SnackBarManager {
  static final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Shows a success snackbar
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppTheme.primaryColor,
      icon: Icons.check_circle_outline,
    );
  }

  /// Shows an error snackbar with user-friendly message
  static void showError(BuildContext context, dynamic error) {
    final message = _translateError(error);
    _show(
      context,
      message: message,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error_outline,
    );
  }

  /// Shows a warning snackbar
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning_amber_outlined,
    );
  }

  /// Shows an info snackbar
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.blue.shade700,
      icon: Icons.info_outline,
    );
  }

  /// Shows a network error snackbar with retry option
  static void showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    _show(
      context,
      message: 'No internet connection. Please check your network.',
      backgroundColor: Colors.red.shade700,
      icon: Icons.wifi_off,
      action: onRetry != null
          ? SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
      duration: const Duration(seconds: 5),
    );
  }

  /// Shows a connection timeout error with retry option
  static void showTimeoutError(
    BuildContext context, {
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    _show(
      context,
      message: customMessage ?? 'Connection timed out. Please try again.',
      backgroundColor: Colors.red.shade700,
      icon: Icons.timer_off_outlined,
      action: onRetry != null
          ? SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
      duration: const Duration(seconds: 5),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: action,
      ),
    );
  }

  /// Translates technical error messages to user-friendly ones
  static String _translateError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Firebase Auth errors
    if (errorString.contains('firebase') || errorString.contains('auth')) {
      return _translateFirebaseError(errorString);
    }

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('failed host lookup')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Connection timed out. Please try again.';
    }

    // Supabase errors
    if (errorString.contains('postgrest') || errorString.contains('supabase')) {
      return _translateSupabaseError(errorString);
    }

    // Google Sign-In errors
    if (errorString.contains('google') && errorString.contains('cancelled')) {
      return 'Sign in was cancelled.';
    }

    // Generic extraction - get the last part after ': '
    if (error.toString().contains(': ')) {
      final parts = error.toString().split(': ');
      final lastPart = parts.last.trim();
      // Capitalize first letter
      if (lastPart.isNotEmpty) {
        return '${lastPart[0].toUpperCase()}${lastPart.substring(1)}';
      }
    }

    return 'Something went wrong. Please try again.';
  }

  static String _translateFirebaseError(String error) {
    // Email/password errors
    if (error.contains('user-not-found')) {
      return 'No account found with this email address.';
    }
    if (error.contains('wrong-password') || error.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (error.contains('user-disabled')) {
      return 'This account has been disabled.';
    }
    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please wait and try again later.';
    }

    // Phone auth errors
    if (error.contains('invalid-phone-number')) {
      return 'Please enter a valid phone number.';
    }
    if (error.contains('invalid-verification-code')) {
      return 'Invalid verification code. Please try again.';
    }
    if (error.contains('session-expired') || error.contains('code-expired')) {
      return 'Verification code expired. Please request a new one.';
    }

    // Biometric errors
    if (error.contains('biometric')) {
      return 'Biometric authentication failed. Please try again.';
    }

    // Generic Firebase error
    if (error.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    return 'Authentication failed. Please try again.';
  }

  static String _translateSupabaseError(String error) {
    if (error.contains('duplicate key') || error.contains('unique constraint')) {
      return 'This record already exists.';
    }
    if (error.contains('permission denied') || error.contains('rls')) {
      return 'You don\'t have permission to perform this action.';
    }
    if (error.contains('not found')) {
      return 'The requested data was not found.';
    }

    return 'Unable to save data. Please try again.';
  }
}
