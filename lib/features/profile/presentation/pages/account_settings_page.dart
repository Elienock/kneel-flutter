import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/data/countries.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/auth/domain/entities/user.dart' show User;
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_state.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_cubit.dart';

/// Comprehensive Account Settings page.
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _morningReminders = true;
  bool _eveningReminders = false;
  bool _answeredAlerts = true;
  TimeOfDay _morningTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 21, minute: 0);

  // Biometric state
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final authCubit = context.read<AuthCubit>();
    final available = await authCubit.isBiometricAvailable();
    final enabled = await authCubit.isBiometricLoginEnabled();

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_biometricLoading) return;

    setState(() => _biometricLoading = true);
    HapticFeedback.lightImpact();

    try {
      final authCubit = context.read<AuthCubit>();

      if (value) {
        // Enable biometric login
        final success = await authCubit.enableBiometricLogin();
        if (mounted) {
          setState(() {
            _biometricEnabled = success;
            _biometricLoading = false;
          });
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
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to enable biometric login'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } else {
        // Disable biometric login
        await authCubit.disableBiometricLogin();
        if (mounted) {
          setState(() {
            _biometricEnabled = false;
            _biometricLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('One-touch login disabled'),
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
        setState(() => _biometricLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().split(':').last}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notification Settings Section
          _buildSectionHeader('Notifications', LucideIcons.bell, isDark),
          const SizedBox(height: 12),
          _buildNotificationSettings(isDark),
          const SizedBox(height: 24),

          // Private Information Section
          _buildSectionHeader('Private Information', LucideIcons.lock, isDark),
          const SizedBox(height: 12),
          _buildPrivateInfo(isDark),
          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader('Security', LucideIcons.shield, isDark),
          const SizedBox(height: 12),
          _buildSecuritySettings(isDark),
          const SizedBox(height: 32),

          // Danger Zone
          _buildDangerZone(isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 51 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Morning Reminders
          _NotificationToggle(
            icon: LucideIcons.sunrise,
            title: 'Morning Reminders',
            subtitle: 'Start your day with prayer',
            value: _morningReminders,
            time: _morningTime,
            onChanged: (value) => setState(() => _morningReminders = value),
            onTimeTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _morningTime,
              );
              if (time != null) {
                setState(() => _morningTime = time);
              }
            },
          ),
          _buildDivider(isDark),

          // Evening Reminders
          _NotificationToggle(
            icon: LucideIcons.moon,
            title: 'Evening Reminders',
            subtitle: 'End your day in gratitude',
            value: _eveningReminders,
            time: _eveningTime,
            onChanged: (value) => setState(() => _eveningReminders = value),
            onTimeTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _eveningTime,
              );
              if (time != null) {
                setState(() => _eveningTime = time);
              }
            },
          ),
          _buildDivider(isDark),

          // Answered Prayer Alerts
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.answeredColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                color: AppTheme.answeredColor,
                size: 20,
              ),
            ),
            title: Text(
              'Answered Prayer Alerts',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Celebrate answered prayers',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            trailing: Switch.adaptive(
              value: _answeredAlerts,
              onChanged: (value) => setState(() => _answeredAlerts = value),
              activeTrackColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateInfo(bool isDark) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        String email = 'user@example.com';
        String? phoneNumber;
        bool emailVerified = false;

        if (authState is Authenticated) {
          email = authState.user.email;
          phoneNumber = authState.user.phoneNumber;
          emailVerified = authState.user.isEmailVerified;
        }

        // Also check profile for phone number
        final profileCubit = context.watch<ProfileCubit>();
        final profile = profileCubit.currentProfile;
        if (profile != null && profile.phoneNumber != null) {
          phoneNumber = profile.phoneNumber;
        }

        // Obfuscate values
        final obfuscatedEmail = _obfuscateEmail(email);
        final obfuscatedPhone = phoneNumber != null
            ? _obfuscatePhone(phoneNumber)
            : 'Not set';
        final hasPhone = phoneNumber != null && phoneNumber.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 51 : 13),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Email
              _InfoTile(
                icon: LucideIcons.mail,
                title: 'Email Address',
                value: obfuscatedEmail,
                isVerified: emailVerified,
              ),
              _buildDivider(isDark),

              // Phone Number
              _InfoTile(
                icon: LucideIcons.phone,
                title: 'Phone Number',
                value: obfuscatedPhone,
                isVerified: hasPhone,
                actionLabel: hasPhone ? null : 'Add',
                onAction: hasPhone ? null : () => _showAddPhoneSheet(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _obfuscatePhone(String phone) {
    if (phone.length <= 4) return phone;
    final visible = phone.substring(0, 4);
    final lastTwo = phone.substring(phone.length - 2);
    final hidden = '•' * (phone.length - 6);
    return '$visible$hidden$lastTwo';
  }

  void _showAddPhoneSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddPhoneSheet(
        onPhoneLinked: () {
          // Refresh profile to get updated phone
          final profileCubit = context.read<ProfileCubit>();
          profileCubit.refreshProfile();
        },
      ),
    );
  }

  Widget _buildSecuritySettings(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 51 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Change Password
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.key,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              'Change Password',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Update your password',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            trailing: Icon(
              LucideIcons.chevronRight,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            onTap: () => _showChangePasswordDialog(),
          ),
          _buildDivider(isDark),

          // Biometric Login (One-Touch Login)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _biometricAvailable
                    ? AppTheme.primaryColor.withAlpha(26)
                    : Colors.grey.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.fingerprint,
                color: _biometricAvailable ? AppTheme.primaryColor : Colors.grey,
                size: 20,
              ),
            ),
            title: Text(
              'One-Touch Login',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _biometricAvailable
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.grey,
              ),
            ),
            subtitle: Text(
              _biometricAvailable
                  ? (_biometricEnabled
                      ? 'Sign in instantly with biometrics'
                      : 'Use fingerprint or face ID to sign in')
                  : 'Not available on this device',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            trailing: _biometricLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch.adaptive(
                    value: _biometricEnabled,
                    onChanged: _biometricAvailable ? _toggleBiometric : null,
                    activeTrackColor: AppTheme.primaryColor,
                  ),
          ),
          _buildDivider(isDark),

          // Two-Factor Authentication
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.smartphone,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              'Two-Factor Authentication',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Add extra security',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Coming Soon',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'DANGER ZONE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.error,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _showDeleteAccountDialog(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delete Account',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'This action cannot be undone',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }

  String _obfuscateEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '$username@$domain';
    }

    final visible = username.substring(0, 2);
    final hidden = '•' * (username.length - 2);
    return '$visible$hidden@$domain';
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Change Password',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Current Password
                      _PasswordField(
                        controller: currentController,
                        label: 'Current Password',
                        obscure: obscureCurrent,
                        onToggle: () => setSheetState(() => obscureCurrent = !obscureCurrent),
                      ),
                      const SizedBox(height: 16),

                      // New Password
                      _PasswordField(
                        controller: newController,
                        label: 'New Password',
                        obscure: obscureNew,
                        onToggle: () => setSheetState(() => obscureNew = !obscureNew),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      _PasswordField(
                        controller: confirmController,
                        label: 'Confirm New Password',
                        obscure: obscureConfirm,
                        onToggle: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (currentController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter current password')),
                              );
                              return;
                            }
                            if (newController.text.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('New password must be at least 6 characters')),
                              );
                              return;
                            }
                            if (newController.text != confirmController.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Passwords do not match')),
                              );
                              return;
                            }

                            // Call Firebase to update password
                            final success = await context.read<AuthCubit>().updatePassword(
                              currentPassword: currentController.text,
                              newPassword: newController.text,
                            );

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            HapticFeedback.mediumImpact();

                            if (mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Password updated successfully'),
                                    backgroundColor: AppTheme.answeredColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Failed to update password. Check your current password.'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Update Password',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Account',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you absolutely sure you want to delete your account?',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This will permanently delete:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _DeleteItem(text: 'All your prayers', isDark: isDark),
              _DeleteItem(text: 'Your prayer history', isDark: isDark),
              _DeleteItem(text: 'Your profile data', isDark: isDark),
              _DeleteItem(text: 'All session records', isDark: isDark),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showFinalConfirmation();
              },
              child: Text(
                'Delete Account',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFinalConfirmation() {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Final Confirmation',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Type "DELETE" to confirm account deletion:',
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                decoration: InputDecoration(
                  hintText: 'Type DELETE',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (confirmController.text.toUpperCase() == 'DELETE') {
                  Navigator.pop(ctx);
                  context.read<AuthCubit>().logout();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please type DELETE to confirm')),
                  );
                }
              },
              child: Text(
                'Confirm Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Notification toggle with time picker.
class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final TimeOfDay time;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTimeTap;

  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.time,
    required this.onChanged,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (value) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTimeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  time.format(context),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primaryColor,
      ),
    );
  }
}

/// Info tile for private information.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isVerified;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.isVerified = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isVerified) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.answeredColor.withAlpha(26),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.checkCircle,
                    size: 12,
                    color: AppTheme.answeredColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.answeredColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      trailing: actionLabel != null
          ? TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            )
          : null,
    );
  }
}

/// Password field widget.
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inter(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: isDark ? Colors.white54 : Colors.black45,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? LucideIcons.eyeOff : LucideIcons.eye,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

/// Delete item bullet point.
class _DeleteItem extends StatelessWidget {
  final String text;
  final bool isDark;

  const _DeleteItem({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(
            LucideIcons.x,
            size: 14,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

/// Add Phone Number bottom sheet with OTP verification.
class _AddPhoneSheet extends StatefulWidget {
  final VoidCallback onPhoneLinked;

  const _AddPhoneSheet({required this.onPhoneLinked});

  @override
  State<_AddPhoneSheet> createState() => _AddPhoneSheetState();
}

class _AddPhoneSheetState extends State<_AddPhoneSheet> {
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  Country _selectedCountry = defaultCountry;
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Resend timer
  Timer? _resendTimer;
  int _resendCountdown = 0;
  static const int _resendCooldown = 60;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _fullPhoneNumber {
    String phone = _phoneController.text.trim();
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '${_selectedCountry.dialCode}$phone';
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

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

  void _sendVerificationCode() {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a phone number');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    context.read<AuthCubit>().linkPhoneNumber(
      phoneNumber: _fullPhoneNumber,
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
        });
        _startResendTimer();
        _otpFocusNodes[0].requestFocus();
      },
      onVerificationFailed: (error) {
        setState(() {
          _errorMessage = error;
          _isLoading = false;
        });
      },
      onLinkSuccess: () {
        // Auto-verified and linked
        _onLinkSuccess();
      },
    );
  }

  void _verifyAndLink() async {
    if (_otpCode.length != 6) {
      setState(() => _errorMessage = 'Please enter the 6-digit code');
      return;
    }

    if (_verificationId == null) {
      setState(() => _errorMessage = 'Session expired. Please request a new code.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await context.read<AuthCubit>().verifyAndLinkPhone(
        verificationId: _verificationId!,
        smsCode: _otpCode,
      );
      _onLinkSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onLinkSuccess() {
    // Sync phone to Supabase profile
    final sanitizedPhone = User.sanitizePhone(_fullPhoneNumber);
    if (sanitizedPhone != null) {
      // The profile will be refreshed by onPhoneLinked callback
    }

    widget.onPhoneLinked();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone number added successfully!'),
          backgroundColor: AppTheme.answeredColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    if (_otpCode.length == 6) {
      _verifyAndLink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _codeSent ? 'Verify Phone' : 'Add Phone Number',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Enter the code sent to $_fullPhoneNumber'
                    : 'Link your phone number for added security',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 24),

              if (!_codeSent) ...[
                // Country picker
                GestureDetector(
                  onTap: () => _showCountryPicker(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBackground : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(_selectedCountry.flag, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCountry.name,
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          _selectedCountry.dialCode,
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 20,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone input
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    prefixText: '${_selectedCountry.dialCode} ',
                    prefixIcon: const Icon(LucideIcons.phone),
                    filled: true,
                    fillColor: isDark ? AppTheme.darkBackground : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ] else ...[
                // OTP input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: isDark ? AppTheme.darkBackground : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                          ),
                        ),
                        onChanged: (v) => _onOtpChanged(index, v),
                      ),
                    );
                  }),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading
                      ? null
                      : (_codeSent ? _verifyAndLink : _sendVerificationCode),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _codeSent ? 'Verify & Link' : 'Send Verification Code',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              // Resend / Back button
              if (_codeSent) ...[
                const SizedBox(height: 16),
                Center(
                  child: _resendCountdown > 0
                      ? Text(
                          'Resend code in ${_resendCountdown}s',
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        )
                      : TextButton(
                          onPressed: () {
                            for (final c in _otpControllers) {
                              c.clear();
                            }
                            _sendVerificationCode();
                          },
                          child: Text(
                            'Resend Code',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CountryPickerSheet(
        selectedCountry: _selectedCountry,
        onCountrySelected: (country) {
          setState(() => _selectedCountry = country);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// Country picker sheet for phone number input.
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
        _filteredCountries = allCountries.where((c) {
          return c.name.toLowerCase().contains(lowerQuery) ||
              c.dialCode.contains(query) ||
              c.code.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Country',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search country',
                prefixIcon: const Icon(LucideIcons.search),
                filled: true,
                fillColor: isDark ? AppTheme.darkBackground : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterCountries,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;

                return ListTile(
                  leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    country.name,
                    style: GoogleFonts.inter(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        country.dialCode,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.check, color: AppTheme.primaryColor, size: 20),
                      ],
                    ],
                  ),
                  onTap: () => widget.onCountrySelected(country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
