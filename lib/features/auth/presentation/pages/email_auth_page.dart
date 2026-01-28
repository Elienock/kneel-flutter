import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/l10n/app_strings.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_state.dart';

enum EmailAuthMode { login, register, forgotPassword }

/// Email authentication page with login, register, and forgot password flows.
class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  EmailAuthMode _mode = EmailAuthMode.login;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _switchMode(EmailAuthMode mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
      _successMessage = null;
      _formKey.currentState?.reset();
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (_mode == EmailAuthMode.register && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final authCubit = context.read<AuthCubit>();

    switch (_mode) {
      case EmailAuthMode.login:
        await authCubit.loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        break;

      case EmailAuthMode.register:
        await authCubit.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim().isNotEmpty
              ? _displayNameController.text.trim()
              : null,
        );
        break;

      case EmailAuthMode.forgotPassword:
        final success = await authCubit.sendPasswordResetEmail(
          _emailController.text.trim(),
        );
        if (success && mounted) {
          setState(() {
            _successMessage = AppStrings.resetEmailSent;
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          setState(() => _errorMessage = state.message.replaceAll('Exception: ', ''));
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: theme.colorScheme.onSurface),
            onPressed: () {
              if (_mode != EmailAuthMode.login) {
                _switchMode(EmailAuthMode.login);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            _getTitle(),
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 32),
                      _buildForm(theme, isDark, isLoading),
                      const SizedBox(height: 24),
                      _buildSubmitButton(isLoading),
                      const SizedBox(height: 16),
                      _buildAlternativeActions(theme, isDark),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_mode) {
      case EmailAuthMode.login:
        return AppStrings.emailLogin;
      case EmailAuthMode.register:
        return AppStrings.createAccount;
      case EmailAuthMode.forgotPassword:
        return AppStrings.forgotPasswordTitle;
    }
  }

  Widget _buildHeader(bool isDark) {
    String title;
    String subtitle;

    switch (_mode) {
      case EmailAuthMode.login:
        title = AppStrings.welcomeBack;
        subtitle = AppStrings.signInToContinue;
        break;
      case EmailAuthMode.register:
        title = AppStrings.createAccount;
        subtitle = AppStrings.joinCommunity;
        break;
      case EmailAuthMode.forgotPassword:
        title = AppStrings.forgotPasswordTitle;
        subtitle = AppStrings.forgotPasswordSubtitle;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
      ],
    );
  }

  Widget _buildForm(ThemeData theme, bool isDark, bool isLoading) {
    return Column(
      children: [
        // Display Name (Register only)
        if (_mode == EmailAuthMode.register)
          _buildTextField(
            controller: _displayNameController,
            enabled: !isLoading,
            label: AppStrings.displayNameOptional,
            hint: AppStrings.displayNameHint,
            icon: LucideIcons.user,
            isDark: isDark,
            textCapitalization: TextCapitalization.words,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

        if (_mode == EmailAuthMode.register) const SizedBox(height: 16),

        // Email Field
        _buildTextField(
          controller: _emailController,
          enabled: !isLoading,
          label: AppStrings.email,
          hint: AppStrings.emailHint,
          icon: LucideIcons.mail,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

        // Password Field (not for forgot password)
        if (_mode != EmailAuthMode.forgotPassword) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            enabled: !isLoading,
            label: AppStrings.password,
            hint: AppStrings.passwordHint,
            icon: LucideIcons.lock,
            isDark: isDark,
            obscureText: _obscurePassword,
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
        ],

        // Confirm Password (Register only)
        if (_mode == EmailAuthMode.register) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            enabled: !isLoading,
            label: AppStrings.confirmPassword,
            hint: AppStrings.confirmPasswordHint,
            icon: LucideIcons.lock,
            isDark: isDark,
            obscureText: _obscureConfirmPassword,
            validator: _validateConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        ],

        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertCircle, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Success Message
        if (_successMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: GoogleFonts.inter(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required bool enabled,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        textCapitalization: textCapitalization,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    String buttonText;
    switch (_mode) {
      case EmailAuthMode.login:
        buttonText = AppStrings.signIn;
        break;
      case EmailAuthMode.register:
        buttonText = AppStrings.signUp;
        break;
      case EmailAuthMode.forgotPassword:
        buttonText = AppStrings.sendResetLink;
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                buttonText,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 600.ms);
  }

  Widget _buildAlternativeActions(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Forgot Password (Login mode only)
        if (_mode == EmailAuthMode.login)
          TextButton(
            onPressed: () => _switchMode(EmailAuthMode.forgotPassword),
            child: Text(
              AppStrings.forgotPassword,
              style: GoogleFonts.inter(color: AppTheme.primaryColor),
            ),
          ),

        const SizedBox(height: 8),

        // Switch between Login and Register
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _mode == EmailAuthMode.register
                  ? AppStrings.alreadyHaveAccount
                  : AppStrings.dontHaveAccount,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            TextButton(
              onPressed: () => _switchMode(
                _mode == EmailAuthMode.register
                    ? EmailAuthMode.login
                    : EmailAuthMode.register,
              ),
              child: Text(
                _mode == EmailAuthMode.register ? AppStrings.signIn : AppStrings.signUp,
                style: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 700.ms);
  }
}
