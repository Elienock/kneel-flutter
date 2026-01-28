import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/l10n/app_strings.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';

/// Email verification banner shown at the top of Today tab.
/// Only shows for email/password users who haven't verified their email.
/// Phone users skip this verification as their phone is already verified.
class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() => _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _isResending = false;
  bool _wasSent = false;

  @override
  void initState() {
    super.initState();
    // Check if email was verified since last check
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    // Sync email verification status from Firebase to Supabase
    final profileCubit = context.read<ProfileCubit>();
    await profileCubit.syncEmailVerificationStatus();
  }

  Future<void> _resendVerification() async {
    if (_isResending || _wasSent) return;

    setState(() => _isResending = true);

    try {
      final profileCubit = context.read<ProfileCubit>();
      final success = await profileCubit.resendEmailVerification();

      if (mounted) {
        setState(() {
          _isResending = false;
          _wasSent = success;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.verificationEmailSent),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        // Only show for profiles that need email verification
        if (state is! ProfileLoaded && state is! ProfileNeedsOnboarding) {
          return const SizedBox.shrink();
        }

        final profile = state is ProfileLoaded
            ? state.profile
            : (state as ProfileNeedsOnboarding).profile;

        // Don't show for phone users or already verified users
        // The provider check ensures phone users never see this banner
        if (!profile.showEmailVerificationBanner) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1), // Soft amber
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFB300).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Mail icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.mail,
                  color: Color(0xFFFF8F00),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.verifyYourEmail,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.toJoinCommunity,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF795548),
                      ),
                    ),
                  ],
                ),
              ),

              // Resend button
              TextButton(
                onPressed: _isResending || _wasSent ? null : _resendVerification,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFFB300).withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _wasSent ? AppStrings.sent : AppStrings.resend,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
