import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A styled social login button for OAuth providers.
class SocialLoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.isLoading = false,
  });

  /// Creates a Google sign-in button.
  factory SocialLoginButton.google({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SocialLoginButton(
      label: 'Continue with Google',
      icon: LucideIcons.chrome,
      onPressed: onPressed,
      backgroundColor: const Color(0xFF7C3AED),
      textColor: Colors.white,
      iconColor: Colors.white,
      isLoading: isLoading,
    );
  }

  /// Creates an Apple sign-in button.
  factory SocialLoginButton.apple({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SocialLoginButton(
      label: 'Continue with Apple',
      icon: LucideIcons.apple,
      onPressed: onPressed,
      backgroundColor: const Color(0xFF1A1A1A),
      textColor: Colors.white,
      iconColor: Colors.white,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
