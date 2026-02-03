import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pinput/pinput.dart';
import 'package:quick_church/core/data/countries.dart';
import 'package:quick_church/core/l10n/app_strings.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_state.dart';

/// Phone authentication page with global country picker and OTP verification.
/// Features:
/// - Premium pinput OTP boxes
/// - 60-second resend timer
/// - Auto-verification detection (skips manual entry)
/// - Country code picker with search
class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  // Unique key for Pinput to prevent GlobalKey conflicts on rebuild
  final _pinputKey = GlobalKey();

  Country _selectedCountry = defaultCountry;
  String? _verificationId;
  bool _codeSent = false;
  String? _errorMessage;
  bool _autoVerified = false;

  // Resend timer (60 seconds anti-spam)
  Timer? _resendTimer;
  int _resendCountdown = 0;
  static const int _resendCooldown = 60;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _fullPhoneNumber {
    String phone = _phoneController.text.trim();
    // Remove leading zero if present
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    return '${_selectedCountry.dialCode}$phone';
  }

  void _startResendTimer() {
    _resendCountdown = _resendCooldown;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _showCountryPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(
        selectedCountry: _selectedCountry,
        onCountrySelected: (country) {
          setState(() => _selectedCountry = country);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _sendVerificationCode() {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _errorMessage = AppStrings.invalidPhoneNumber);
      return;
    }

    // Validate minimum phone length
    if (_phoneController.text.trim().length < 6) {
      setState(() => _errorMessage = 'Phone number too short');
      return;
    }

    setState(() {
      _errorMessage = null;
      _autoVerified = false;
    });

    HapticFeedback.mediumImpact();

    context.read<AuthCubit>().sendPhoneVerificationCode(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (verificationId) {
        if (mounted && !_autoVerified) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _errorMessage = null;
          });
          // Start 60-second resend cooldown
          _startResendTimer();
          // Focus OTP input
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _otpFocusNode.requestFocus();
          });
        }
      },
      onVerificationFailed: (error) {
        if (mounted) {
          setState(() => _errorMessage = error);
        }
      },
    );
  }

  void _verifyCode(String code) {
    if (code.length != 6) return;
    if (_verificationId == null) {
      setState(() => _errorMessage = AppStrings.sessionExpired);
      return;
    }
    if (_autoVerified) {
      // Already verified via auto-verification
      return;
    }

    setState(() => _errorMessage = null);
    HapticFeedback.mediumImpact();

    context.read<AuthCubit>().verifyPhoneCode(
      verificationId: _verificationId!,
      smsCode: code,
    );
  }

  void _resendCode() {
    if (_resendCountdown > 0) return;

    // Clear OTP
    _otpController.clear();
    setState(() => _errorMessage = null);

    // Resend verification code
    context.read<AuthCubit>().sendPhoneVerificationCode(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _errorMessage = null;
          });
          _startResendTimer();
          _otpFocusNode.requestFocus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('New code sent!'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onVerificationFailed: (error) {
        if (mounted) {
          setState(() => _errorMessage = error);
        }
      },
    );
  }

  void _resetToPhoneInput() {
    _resendTimer?.cancel();
    setState(() {
      _codeSent = false;
      _verificationId = null;
      _errorMessage = null;
      _resendCountdown = 0;
      _autoVerified = false;
    });
    _otpController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Auto-verification or manual verification succeeded
          setState(() => _autoVerified = true);
          // Navigation will be handled by SmartRouter
        } else if (state is AuthError) {
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
              HapticFeedback.selectionClick();
              if (_codeSent) {
                _resetToPhoneInput();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            _codeSent ? AppStrings.verifyCode : AppStrings.phoneLogin,
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _codeSent
                    ? _buildOtpScreen(theme, isDark, isLoading)
                    : _buildPhoneInputScreen(theme, isDark, isLoading),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhoneInputScreen(ThemeData theme, bool isDark, bool isLoading) {
    return Column(
      key: const ValueKey('phone_input_screen'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.enterPhoneNumber,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 8),

        Text(
          'We\'ll send you a verification code via SMS',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

        const SizedBox(height: 32),

        // Country Code Picker - Premium Style
        GestureDetector(
          onTap: _showCountryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withAlpha(20),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(_selectedCountry.flag, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCountry.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedCountry.dialCode,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronDown,
                  size: 20,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

        const SizedBox(height: 16),

        // Phone Number Input - Premium Style
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withAlpha(20),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 1,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            decoration: InputDecoration(
              hintText: AppStrings.phoneNumberHint,
              hintStyle: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.phone,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCountry.dialCode,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 1,
                      height: 24,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ],
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.error.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertCircle, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Send Code Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _sendVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.send, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.sendVerificationCode,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

        const Spacer(),

        // Privacy note
        Center(
          child: Text(
            'Standard SMS rates may apply',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
      ],
    );
  }

  Widget _buildOtpScreen(ThemeData theme, bool isDark, bool isLoading) {
    // Premium Pinput theme - unique key already defined at class level (_pinputKey)
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(50),
          width: 1.5,
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.error,
          width: 1.5,
        ),
      ),
    );

    return Column(
      key: const ValueKey('otp_screen'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              LucideIcons.messageSquare,
              color: AppTheme.primaryColor,
              size: 36,
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

        const SizedBox(height: 24),

        Center(
          child: Text(
            AppStrings.enterVerificationCode,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

        const SizedBox(height: 8),

        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              children: [
                const TextSpan(text: 'Code sent to '),
                TextSpan(
                  text: _fullPhoneNumber,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

        const SizedBox(height: 40),

        // Premium OTP Input with Pinput
        Center(
          child: Pinput(
            key: _pinputKey,
            controller: _otpController,
            focusNode: _otpFocusNode,
            length: 6,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            submittedPinTheme: submittedPinTheme,
            errorPinTheme: errorPinTheme,
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            cursor: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 2,
                  height: 24,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
            onCompleted: _verifyCode,
            onChanged: (value) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            hapticFeedbackType: HapticFeedbackType.lightImpact,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

        // Error Message
        if (_errorMessage != null) ...[
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertCircle, color: theme.colorScheme.error, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Verify Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading || _otpController.text.length != 6
                ? null
                : () => _verifyCode(_otpController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark
                  ? Colors.white12
                  : Colors.black12,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.checkCircle, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.verifyCode,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

        const SizedBox(height: 24),

        // Resend Code & Timer
        Center(
          child: Column(
            children: [
              if (_resendCountdown > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 16,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Resend in ${_resendCountdown}s',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                )
              else
                TextButton.icon(
                  onPressed: isLoading ? null : _resendCode,
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  label: Text(
                    'Resend Code',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: isLoading ? null : _resetToPhoneInput,
                child: Text(
                  'Change Phone Number',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
      ],
    );
  }
}

/// Bottom sheet for selecting a country with search functionality.
class _CountryPickerSheet extends StatefulWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onCountrySelected;

  const _CountryPickerSheet({
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<Country> _filteredCountries = allCountries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = allCountries;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCountries = allCountries.where((country) {
          return country.name.toLowerCase().contains(lowerQuery) ||
                 country.dialCode.contains(query) ||
                 country.code.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.selectCountry,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackground : Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.searchCountry,
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: const Icon(LucideIcons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: _filterCountries,
              ),
            ),
          ),

          // Country list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Text(country.flag, style: const TextStyle(fontSize: 28)),
                  title: Text(
                    country.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withAlpha(20)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          country.dialCode,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : (isDark ? Colors.white54 : Colors.black45),
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          LucideIcons.checkCircle,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onCountrySelected(country);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
