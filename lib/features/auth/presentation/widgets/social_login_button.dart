import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/l10n/app_strings.dart';

/// A styled social login button for OAuth providers.
class SocialLoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final bool isLoading;
  final bool outlined;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.isLoading = false,
    this.outlined = false,
  });

  /// Creates a Google sign-in button.
  factory SocialLoginButton.google({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SocialLoginButton(
      label: AppStrings.continueWithGoogle,
      icon: LucideIcons.chrome,
      onPressed: onPressed,
      backgroundColor: const Color(0xFF7C3AED),
      textColor: Colors.white,
      iconColor: Colors.white,
      isLoading: isLoading,
    );
  }

  /// Creates a Phone sign-in button.
  factory SocialLoginButton.phone({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SocialLoginButton(
      label: AppStrings.continueWithPhone,
      icon: LucideIcons.smartphone,
      onPressed: onPressed,
      backgroundColor: const Color(0xFF059669),
      textColor: Colors.white,
      iconColor: Colors.white,
      isLoading: isLoading,
    );
  }

  /// Creates an Email sign-in button.
  factory SocialLoginButton.email({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SocialLoginButton(
      label: AppStrings.emailLogin,
      icon: LucideIcons.mail,
      onPressed: onPressed,
      backgroundColor: const Color(0xFF475569),
      textColor: Colors.white,
      iconColor: Colors.white,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: backgroundColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _buildContent(backgroundColor),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _buildContent(textColor),
      ),
    );
  }

  Widget _buildContent(Color contentColor) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(contentColor),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
