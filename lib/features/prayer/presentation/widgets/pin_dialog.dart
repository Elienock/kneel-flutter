import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quick_church/core/theme/app_theme.dart';

/// PIN manager for storing and verifying PINs.
class PinManager {
  static const String _pinKey = 'app_pin';
  static const String _pinSetKey = 'pin_is_set';

  /// Check if a PIN has been set.
  static Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinSetKey) ?? false;
  }

  /// Save a new PIN.
  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_pinSetKey, true);
  }

  /// Verify if the entered PIN is correct.
  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey);
    return savedPin == pin;
  }

  /// Reset the PIN (used for "Forgot PIN").
  static Future<void> resetPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_pinSetKey, false);
  }
}

/// A modern PIN entry dialog for unlocking private prayers.
class PinDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;
  final bool isSetupMode;

  const PinDialog({
    super.key,
    this.title = 'Enter PIN',
    this.subtitle,
    required this.onSuccess,
    this.onCancel,
    this.isSetupMode = false,
  });

  /// Shows the PIN dialog and returns true if PIN is correct.
  /// If no PIN is set, it will first ask to create one.
  static Future<bool> show(BuildContext context, {
    String title = 'Enter PIN',
    String? subtitle,
  }) async {
    // Check if PIN is set
    final isPinSet = await PinManager.isPinSet();

    if (!isPinSet) {
      // Show setup dialog first
      final setupResult = await _showSetupDialog(context);
      if (!setupResult) return false;
    }

    if (!context.mounted) return false;

    // Show verification dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinDialog(
        title: title,
        subtitle: subtitle,
        onSuccess: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  /// Shows the PIN setup dialog for first-time lock.
  static Future<bool> showSetup(BuildContext context) async {
    return await _showSetupDialog(context);
  }

  static Future<bool> _showSetupDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _PinSetupDialog(),
    );
    return result ?? false;
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final List<String> _enteredPin = [];
  bool _isError = false;
  bool _isSuccess = false;
  bool _isVerifying = false;

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 4 && !_isVerifying) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin.add(number);
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty && !_isVerifying) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin.removeLast();
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);

    final enteredPin = _enteredPin.join();
    final isCorrect = await PinManager.verifyPin(enteredPin);

    if (isCorrect) {
      setState(() => _isSuccess = true);
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      widget.onSuccess();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isError = true;
        _enteredPin.clear();
        _isVerifying = false;
      });
    }
  }

  Future<void> _handleForgotPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
        ),
        title: Text('Reset PIN?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'This will unlock all locked prayers and you\'ll need to set a new PIN next time you lock a prayer.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.urgentColor,
            ),
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PinManager.resetPin();
      if (mounted) {
        Navigator.of(context).pop(true); // Allow access after reset
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.dialogRadius)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isSuccess
                    ? AppTheme.answeredColor.withAlpha(26)
                    : _isError
                        ? AppTheme.urgentColor.withAlpha(26)
                        : AppTheme.primaryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSuccess ? LucideIcons.unlock : LucideIcons.lock,
                size: 32,
                color: _isSuccess
                    ? AppTheme.answeredColor
                    : _isError
                        ? AppTheme.urgentColor
                        : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.title,
              style: theme.textTheme.titleLarge,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isError
                        ? AppTheme.urgentColor
                        : _isSuccess
                            ? AppTheme.answeredColor
                            : isFilled
                                ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
                                : Colors.transparent,
                    border: Border.all(
                      color: _isError
                          ? AppTheme.urgentColor
                          : _isSuccess
                              ? AppTheme.answeredColor
                              : isDark
                                  ? Colors.white.withAlpha(77)
                                  : const Color(0xFF1C1C1E).withAlpha(77),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            // Error message
            if (_isError)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Incorrect PIN. Try again.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.urgentColor,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Number pad
            _buildNumberPad(context),

            const SizedBox(height: 16),

            // Forgot PIN & Cancel buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _handleForgotPin,
                  child: Text(
                    'Forgot PIN?',
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.outline,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['1', '2', '3'].map((n) => _NumberButton(
            number: n,
            onPressed: () => _onNumberPressed(n),
            isDark: isDark,
          )).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['4', '5', '6'].map((n) => _NumberButton(
            number: n,
            onPressed: () => _onNumberPressed(n),
            isDark: isDark,
          )).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['7', '8', '9'].map((n) => _NumberButton(
            number: n,
            onPressed: () => _onNumberPressed(n),
            isDark: isDark,
          )).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72),
            _NumberButton(
              number: '0',
              onPressed: () => _onNumberPressed('0'),
              isDark: isDark,
            ),
            SizedBox(
              width: 72,
              height: 56,
              child: IconButton(
                onPressed: _onBackspacePressed,
                icon: Icon(
                  LucideIcons.delete,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// PIN setup dialog for creating a new PIN.
class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog();

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final List<String> _firstPin = [];
  final List<String> _confirmPin = [];
  bool _isConfirmStep = false;
  bool _isError = false;
  String _errorMessage = '';

  void _onNumberPressed(String number) {
    HapticFeedback.lightImpact();

    if (_isConfirmStep) {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin.add(number);
          _isError = false;
        });

        if (_confirmPin.length == 4) {
          _verifyMatch();
        }
      }
    } else {
      if (_firstPin.length < 4) {
        setState(() {
          _firstPin.add(number);
          _isError = false;
        });

        if (_firstPin.length == 4) {
          setState(() => _isConfirmStep = true);
        }
      }
    }
  }

  void _onBackspacePressed() {
    HapticFeedback.lightImpact();

    if (_isConfirmStep) {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin.removeLast();
          _isError = false;
        });
      } else {
        setState(() {
          _isConfirmStep = false;
          _firstPin.clear();
        });
      }
    } else {
      if (_firstPin.isNotEmpty) {
        setState(() {
          _firstPin.removeLast();
          _isError = false;
        });
      }
    }
  }

  Future<void> _verifyMatch() async {
    if (_firstPin.join() == _confirmPin.join()) {
      await PinManager.setPin(_firstPin.join());
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _isError = true;
        _errorMessage = 'PINs don\'t match. Try again.';
        _confirmPin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentPin = _isConfirmStep ? _confirmPin : _firstPin;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.dialogRadius)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.keyRound,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _isConfirmStep ? 'Confirm PIN' : 'Create PIN',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _isConfirmStep
                  ? 'Enter the same PIN again'
                  : 'Set a 4-digit PIN to lock your prayers',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < currentPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isError
                        ? AppTheme.urgentColor
                        : isFilled
                            ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
                            : Colors.transparent,
                    border: Border.all(
                      color: _isError
                          ? AppTheme.urgentColor
                          : isDark
                              ? Colors.white.withAlpha(77)
                              : const Color(0xFF1C1C1E).withAlpha(77),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            // Error message
            if (_isError)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.urgentColor,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Number pad
            _buildNumberPad(context),

            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['1', '2', '3'].map((n) => _NumberButton(
            number: n,
            onPressed: () => _onNumberPressed(n),
            isDark: isDark,
          )).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['4', '5', '6'].map((n) => _NumberButton(
            number: n,
            onPressed: () => _onNumberPressed(n),
            isDark: isDark,
          )).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['7', '8', '9'].map((n) => _NumberButton(
            number: n,
            onPressed: () => _onNumberPressed(n),
            isDark: isDark,
          )).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72),
            _NumberButton(
              number: '0',
              onPressed: () => _onNumberPressed('0'),
              isDark: isDark,
            ),
            SizedBox(
              width: 72,
              height: 56,
              child: IconButton(
                onPressed: _onBackspacePressed,
                icon: Icon(
                  LucideIcons.delete,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Number button for the PIN pad.
class _NumberButton extends StatelessWidget {
  final String number;
  final VoidCallback onPressed;
  final bool isDark;

  const _NumberButton({
    required this.number,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withAlpha(26)
                : const Color(0xFFF2F2F7),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
