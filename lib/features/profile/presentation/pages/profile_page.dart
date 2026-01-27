import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_state.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'package:quick_church/features/profile/presentation/pages/settings_page.dart';

/// Profile page showing user info and settings navigation.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context),
            const SizedBox(height: 24),

            // Stats Summary
            _buildStatsSummary(context),
            const SizedBox(height: 24),

            // Settings Tiles
            _buildSettingsTiles(context),
            const SizedBox(height: 24),

            // Logout Button
            _buildLogoutButton(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String displayName = 'Prayer Warrior';
        String email = 'user@example.com';
        String? photoUrl;

        if (state is Authenticated) {
          displayName = state.user.displayName;
          email = state.user.email;
          photoUrl = state.user.photoUrl;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha:0.1),
                theme.colorScheme.secondary.withValues(alpha:0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha:0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<PrayerCubit, PrayerState>(
      builder: (context, state) {
        int totalPrayers = 0;
        int answeredPrayers = 0;
        int streak = 7; // Mock streak for now

        if (state is PrayerLoaded) {
          totalPrayers = state.prayers.length;
          answeredPrayers = state.prayers
              .where((p) => p.status.name == 'answered')
              .length;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha:0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: totalPrayers.toString(),
                label: 'Prayers',
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withValues(alpha:0.2),
              ),
              _StatItem(
                value: answeredPrayers.toString(),
                label: 'Answered',
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withValues(alpha:0.2),
              ),
              _StatItem(
                value: '$streak',
                label: 'Day Streak',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTiles(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha:0.1),
        ),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: LucideIcons.bell,
            title: 'Notifications',
            subtitle: 'Reminder settings',
            onTap: () {
              // Navigate to notification settings
            },
          ),
          _SettingsDivider(),
          _SettingsTile(
            icon: LucideIcons.fingerprint,
            title: 'Biometric Lock',
            subtitle: 'Secure your prayers',
            onTap: () {
              // Toggle biometric lock
            },
          ),
          _SettingsDivider(),
          _SettingsTile(
            icon: LucideIcons.globe,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              // Show language picker
            },
          ),
          _SettingsDivider(),
          _SettingsTile(
            icon: LucideIcons.download,
            title: 'Backup & Export',
            subtitle: 'Save your data',
            onTap: () {
              // Navigate to backup page
            },
          ),
          _SettingsDivider(),
          _SettingsTile(
            icon: LucideIcons.helpCircle,
            title: 'Help & Support',
            subtitle: 'FAQs and contact',
            onTap: () {
              // Show help
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<AuthCubit>().logout();
                  },
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        icon: const Icon(LucideIcons.logOut),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(
            color: Theme.of(context).colorScheme.error.withValues(alpha:0.5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha:0.6),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha:0.6),
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: theme.colorScheme.onSurface.withValues(alpha:0.4),
      ),
      onTap: onTap,
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outline.withValues(alpha:0.1),
    );
  }
}
