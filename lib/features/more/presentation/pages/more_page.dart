import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:quick_church/features/community/presentation/pages/community_page.dart';
import 'package:quick_church/features/insights/presentation/pages/insights_page.dart';
import 'package:quick_church/features/more/presentation/pages/testimony_vault_page.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';
import 'package:quick_church/features/profile/presentation/bloc/language_cubit.dart';
import 'package:quick_church/features/profile/presentation/pages/profile_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// More page - Hub for profile, settings, and additional features.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Profile Section
              _buildProfileSection(context, isDark),
              const SizedBox(height: 24),

              // Personal Content Group
              _buildMenuGroup(
                context,
                isDark,
                items: [
                  _MenuItem(
                    icon: LucideIcons.users,
                    label: 'Friends',
                    trailing: '12',
                    onTap: () => _navigateTo(context, const CommunityPage()),
                  ),
                  _MenuItem(
                    icon: LucideIcons.userCheck,
                    label: 'Following',
                    trailing: '8',
                    onTap: () => _navigateTo(context, const CommunityPage()),
                  ),
                  _MenuItem(
                    icon: LucideIcons.barChart2,
                    label: 'Insights',
                    onTap: () => _navigateTo(context, const InsightsPage()),
                  ),
                  _MenuItem(
                    icon: LucideIcons.globe,
                    label: 'Community',
                    onTap: () => _navigateTo(context, const CommunityPage()),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Spiritual Tools Group
              _buildMenuGroup(
                context,
                isDark,
                items: [
                  _MenuItem(
                    icon: LucideIcons.sun,
                    label: 'Verse of the Day',
                    onTap: () => _showVerseOfTheDay(context),
                  ),
                  _MenuItem(
                    icon: LucideIcons.bookMarked,
                    label: 'Testimony Vault',
                    onTap: () => _navigateTo(context, const TestimonyVaultPage()),
                  ),
                  _MenuItem(
                    icon: LucideIcons.playCircle,
                    label: 'Videos',
                    onTap: () => _showComingSoon(context, 'Videos'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // App Settings Group
              _buildMenuGroup(
                context,
                isDark,
                items: [
                  _MenuItem(
                    icon: LucideIcons.share2,
                    label: 'Share Kneel',
                    onTap: () => _shareApp(context),
                  ),
                  _MenuItem(
                    icon: LucideIcons.info,
                    label: 'About',
                    onTap: () => _showAbout(context),
                  ),
                  _MenuItem(
                    icon: LucideIcons.helpCircle,
                    label: 'Help',
                    onTap: () => _showHelp(context),
                  ),
                  _MenuItem(
                    icon: LucideIcons.star,
                    label: 'Rate App',
                    onTap: () => _rateApp(context),
                  ),
                  _MenuItem(
                    icon: LucideIcons.languages,
                    label: 'Language',
                    trailing: _getCurrentLanguage(context),
                    onTap: () => _showLanguagePicker(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sign Out Group
              _buildMenuGroup(
                context,
                isDark,
                items: [
                  _MenuItem(
                    icon: LucideIcons.logOut,
                    label: 'Sign Out',
                    isDestructive: true,
                    onTap: () => _confirmSignOut(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // App Version
              Text(
                'Kneel v2.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, bool isDark) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final profile = state is ProfileLoaded ? state.profile : null;
        final displayName = profile?.displayName ?? 'User';
        final photoUrl = profile?.photoUrl;

        return GestureDetector(
          onTap: () => _navigateTo(context, const ProfilePage()),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 3,
                  ),
                  image: photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photoUrl == null
                    ? Icon(
                        LucideIcons.user,
                        size: 36,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      )
                    : null,
              ),
              const SizedBox(height: 12),

              // Name
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Tap to edit
              Text(
                'Tap to view profile',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuGroup(
    BuildContext context,
    bool isDark, {
    required List<_MenuItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          return _buildMenuItem(context, isDark, item);
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, bool isDark, _MenuItem item) {
    final textColor = item.isDestructive
        ? Colors.red
        : (isDark ? Colors.white : Colors.black87);

    final iconColor = item.isDestructive
        ? Colors.red
        : AppTheme.primaryColor;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        item.onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 22,
              color: iconColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (item.trailing != null)
              Text(
                item.trailing!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  String _getCurrentLanguage(BuildContext context) {
    final locale = context.read<LanguageCubit>().state;
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'pt':
        return 'Portuguese';
      default:
        return 'English';
    }
  }

  void _showVerseOfTheDay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              LucideIcons.sun,
              size: 48,
              color: AppTheme.goldenPromise,
            ),
            const SizedBox(height: 16),
            Text(
              'Verse of the Day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '"For I know the plans I have for you," declares the Lord, "plans to prosper you and not to harm you, plans to give you hope and a future."',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '— Jeremiah 29:11',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(
                        text: '"For I know the plans I have for you," declares the Lord, "plans to prosper you and not to harm you, plans to give you hope and a future." — Jeremiah 29:11',
                      ));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verse copied!')),
                      );
                    },
                    icon: const Icon(LucideIcons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Share.share(
                        '"For I know the plans I have for you," declares the Lord, "plans to prosper you and not to harm you, plans to give you hope and a future." — Jeremiah 29:11\n\nShared via Kneel App',
                      );
                    },
                    icon: const Icon(LucideIcons.share2, size: 18),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _shareApp(BuildContext context) {
    Share.share(
      'Check out Kneel - Your Personal Prayer Companion! Download now and grow in your faith journey.\n\nhttps://kneel.app',
      subject: 'Kneel - Prayer App',
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Kneel',
      applicationVersion: 'v2.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          LucideIcons.heart,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
          'Kneel is your personal prayer companion, designed to help you grow in your faith journey through focused prayer, Bible study, and spiritual tracking.',
        ),
      ],
    );
  }

  void _showHelp(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              LucideIcons.helpCircle,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Need Help?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(LucideIcons.mail),
              title: const Text('Email Support'),
              subtitle: const Text('support@kneel.app'),
              onTap: () => launchUrl(Uri.parse('mailto:support@kneel.app')),
            ),
            ListTile(
              leading: const Icon(LucideIcons.messageCircle),
              title: const Text('FAQ'),
              subtitle: const Text('Common questions answered'),
              onTap: () => _showComingSoon(context, 'FAQ'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _rateApp(BuildContext context) {
    // TODO: Link to app store
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you! App store rating coming soon.'),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCubit = context.read<LanguageCubit>();
    final currentLocale = languageCubit.state;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              ('en', 'English'),
              ('es', 'Spanish'),
              ('fr', 'French'),
              ('pt', 'Portuguese'),
            ].map((lang) {
              final isSelected = currentLocale.languageCode == lang.$1;
              return ListTile(
                leading: Icon(
                  isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                  color: isSelected ? AppTheme.primaryColor : null,
                ),
                title: Text(lang.$2),
                onTap: () {
                  languageCubit.setLanguageCode(lang.$1);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
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
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Menu item data class.
class _MenuItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.isDestructive = false,
    required this.onTap,
  });
}
