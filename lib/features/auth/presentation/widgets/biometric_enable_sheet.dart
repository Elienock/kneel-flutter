import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';

/// Bottom sheet to prompt users to enable biometric re-authentication
/// after completing onboarding.
class BiometricEnableSheet extends StatefulWidget {
  const BiometricEnableSheet({super.key});

  /// Shows the biometric enable sheet.
  /// Returns true if biometric was enabled, false otherwise.
  static Future<bool> show(BuildContext context) async {
    // First check if biometrics are available
    final authCubit = context.read<AuthCubit>();
    final available = await authCubit.isBiometricAvailable();

    if (!available) {
      // Biometrics not available on device - skip silently
      return false;
    }

    // Check if already enabled
    final alreadyEnabled = await authCubit.isBiometricLoginEnabled();
    if (alreadyEnabled) {
      return true;
    }

    if (!context.mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) => const BiometricEnableSheet(),
    );

    return result ?? false;
  }

  @override
  State<BiometricEnableSheet> createState() => _BiometricEnableSheetState();
}

class _BiometricEnableSheetState extends State<BiometricEnableSheet> {
  bool _isLoading = false;

  Future<void> _enableBiometrics() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final authCubit = context.read<AuthCubit>();
      final success = await authCubit.enableBiometricLogin();

      if (mounted) {
        Navigator.of(context).pop(success);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('One-touch login enabled!'),
              backgroundColor: AppTheme.answeredColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enable: ${e.toString().split(':').last}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _skipForNow() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  LucideIcons.fingerprint,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Enable One-Touch Login?',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Use your fingerprint or face to sign in instantly next time. Your credentials are stored securely on this device.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Enable button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enableBiometrics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.fingerprint, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Enable One-Touch Login',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Skip button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _isLoading ? null : _skipForNow,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white60 : Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Maybe Later',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
