import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_church/core/l10n/app_strings.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_state.dart';
import 'package:quick_church/features/auth/presentation/pages/phone_auth_page.dart';
import 'package:quick_church/features/auth/presentation/pages/email_auth_page.dart';
import 'package:quick_church/features/auth/presentation/widgets/social_login_button.dart';
import 'package:quick_church/features/auth/presentation/widgets/biometric_login_button.dart';

/// The authentication page with premium UI and branding.
/// Displays social login options and biometric authentication.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _biometricAvailable = false;
  bool _hasPreviousSession = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final authCubit = context.read<AuthCubit>();
    final available = await authCubit.isBiometricAvailable();
    final hasSession = await authCubit.hasPreviousSession();

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _hasPreviousSession = hasSession;
      });
    }
  }

  void _navigateToPhoneAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneAuthPage()),
    );
  }

  void _navigateToEmailAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmailAuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.select<AuthCubit, bool>(
      (cubit) => cubit.state is AuthLoading,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Animated Logo - Centered at top
                _buildLogo(context)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 24),

                // Welcome Text
                _buildWelcomeText(context)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideY(begin: 0.2, end: 0),

                const Spacer(flex: 2),

                // Login Buttons
                _buildLoginButtons(context, isLoading)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Biometric Button (only show if available AND user has logged in before)
                if (_biometricAvailable && _hasPreviousSession)
                  BiometricLoginButton(
                    onPressed: () => context.read<AuthCubit>().loginWithBiometrics(),
                    isLoading: isLoading,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideY(begin: 0.2, end: 0),

                const Spacer(),

                // Terms Text
                _buildTermsText(context)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 800.ms),

                const SizedBox(height: 16),

                // Branding footer - "from Claudine Tech"
                _buildBrandingFooter(context)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 900.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.appName,
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          AppStrings.appTagline,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Track your prayers, build spiritual habits,\nand grow in faith together.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.black45,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginButtons(BuildContext context, bool isLoading) {
    return Column(
      children: [
        // Continue with Google
        SocialLoginButton.google(
          onPressed: () => context.read<AuthCubit>().loginWithGoogle(),
          isLoading: isLoading,
        ),

        const SizedBox(height: 12),

        // Continue with Phone
        SocialLoginButton.phone(
          onPressed: _navigateToPhoneAuth,
          isLoading: isLoading,
        ),

        const SizedBox(height: 12),

        // Email Login
        SocialLoginButton.email(
          onPressed: _navigateToEmailAuth,
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildTermsText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      AppStrings.termsText,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBrandingFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.fromClaudineTech,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}
