import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_state.dart';
import 'package:quick_church/features/auth/presentation/widgets/social_login_button.dart';
import 'package:quick_church/features/auth/presentation/widgets/biometric_login_button.dart';

/// The authentication page with premium UI.
/// Displays social login options and biometric authentication.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await context.read<AuthCubit>().isBiometricAvailable();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Animated Logo
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

                // Biometric Button
                if (_biometricAvailable)
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
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
          'Kneel',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    return Column(
      children: [
        Text(
          'Your Personal Prayer Companion',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Track your prayers, build spiritual habits,\nand grow in faith together.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginButtons(BuildContext context, bool isLoading) {
    return Column(
      children: [
        SocialLoginButton.google(
          onPressed: () => context.read<AuthCubit>().loginWithGoogle(),
          isLoading: isLoading,
        ),
        const SizedBox(height: 12),
        SocialLoginButton.apple(
          onPressed: () => context.read<AuthCubit>().loginWithApple(),
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildTermsText(BuildContext context) {
    return Text(
      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
      textAlign: TextAlign.center,
    );
  }
}
