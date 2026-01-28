import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_state.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';
import 'package:quick_church/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:quick_church/features/profile/presentation/pages/account_settings_page.dart';
import 'package:quick_church/features/profile/presentation/widgets/edit_bio_sheet.dart';

/// YouVersion-style Profile page with comprehensive user info.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
                  );
                },
              ),
            ],
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // YouVersion-style Profile Header
                const _ProfileHeader(),
                const SizedBox(height: 24),

                // Stats Summary with Lightning Bolt Streak
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _StatsSummary(),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _QuickActions(),
                ),
                const SizedBox(height: 24),

                // Settings Tiles
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _SettingsTiles(),
                ),
                const SizedBox(height: 24),

                // Logout Button
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _LogoutButton(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// YouVersion-style profile header with avatar, name, location, and bio.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        String displayName = 'Prayer Warrior';
        String? photoUrl;
        String location = 'Location not set';
        String bio = 'I am Holy and consecrated to GOD';

        if (state is ProfileLoaded) {
          displayName = state.profile.displayName;
          photoUrl = state.profile.photoUrl;
          location = state.profile.locationCity ?? 'Location not set';
          bio = state.profile.bio;
        } else if (state is ProfileNeedsOnboarding) {
          displayName = state.profile.displayName;
          photoUrl = state.profile.photoUrl;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar with edit button
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withAlpha(179),
                        ],
                      ),
                    ),
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              placeholder: (_, __) => _buildInitials(displayName),
                              errorWidget: (_, __, ___) => _buildInitials(displayName),
                            ),
                          )
                        : _buildInitials(displayName),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfilePage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.pencil,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                displayName,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Location
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    location,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bio with edit tap
              GestureDetector(
                onTap: () => EditBioSheet.show(context, bio),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          bio,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.pencil,
                        size: 14,
                        color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: GoogleFonts.outfit(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Stats summary with lightning bolt streak.
class _StatsSummary extends StatelessWidget {
  const _StatsSummary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<PrayerCubit, PrayerState>(
      builder: (context, state) {
        int totalPrayers = 0;
        int answeredPrayers = 0;
        int streak = 7; // TODO: Calculate from real data

        if (state is PrayerLoaded) {
          totalPrayers = state.prayers.length;
          answeredPrayers = state.prayers
              .where((p) => p.status.name == 'answered')
              .length;
        }

        return Container(
          padding: const EdgeInsets.all(20),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: totalPrayers.toString(),
                label: 'Prayers',
                icon: LucideIcons.heart,
                color: AppTheme.primaryColor,
              ),
              Container(
                width: 1,
                height: 50,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              _StatItem(
                value: answeredPrayers.toString(),
                label: 'Answered',
                icon: LucideIcons.sparkles,
                color: AppTheme.answeredColor,
              ),
              Container(
                width: 1,
                height: 50,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              // Lightning Bolt Streak
              _StatItem(
                value: '$streak',
                label: 'Day Streak',
                icon: LucideIcons.zap,
                color: const Color(0xFFFFA500),
                isStreak: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Individual stat item.
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isStreak;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.isStreak = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isStreak)
              Icon(icon, size: 24, color: color),
            if (isStreak) const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

/// Quick action buttons.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: LucideIcons.userCircle,
            label: 'Edit Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: LucideIcons.share2,
            label: 'Share Profile',
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Quick action card.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Icon(
              icon,
              size: 28,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings tiles section.
class _SettingsTiles extends StatelessWidget {
  const _SettingsTiles();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          _SettingsTile(
            icon: LucideIcons.bell,
            title: 'Notifications',
            subtitle: 'Manage reminders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
              );
            },
          ),
          _buildDivider(isDark),
          _SettingsTile(
            icon: LucideIcons.shield,
            title: 'Privacy & Security',
            subtitle: 'Account protection',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
              );
            },
          ),
          _buildDivider(isDark),
          _SettingsTile(
            icon: LucideIcons.helpCircle,
            title: 'Help & Support',
            subtitle: 'FAQs and contact',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center coming soon')),
              );
            },
          ),
          _buildDivider(isDark),
          _SettingsTile(
            icon: LucideIcons.info,
            title: 'About Kneel',
            subtitle: 'Version 2.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Kneel',
                applicationVersion: '2.0.0',
                applicationLegalese: '© 2024 Claudine Tech. All rights reserved.',
              );
            },
          ),
        ],
      ),
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
}

/// Individual settings tile.
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
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: isDark ? Colors.white38 : Colors.black26,
      ),
      onTap: onTap,
    );
  }
}

/// Logout button.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(LucideIcons.logOut),
        label: Text(
          'Sign Out',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(
            color: Theme.of(context).colorScheme.error.withAlpha(128),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProfileCubit>().clear();
              context.read<AuthCubit>().logout();
              Navigator.pop(context);
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
