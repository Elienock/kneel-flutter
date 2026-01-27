import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/features/profile/presentation/bloc/language_cubit.dart';
import 'package:quick_church/features/profile/presentation/pages/notification_settings_page.dart';
import 'package:quick_church/features/profile/presentation/pages/backup_page.dart';

/// Settings page with app configuration options.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricEnabled = false;
  String _selectedTheme = 'System';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          _buildSectionHeader(context, 'Account'),
          const SizedBox(height: 8),
          _buildSettingsCard(context, [
            _buildNavigationTile(
              context,
              icon: LucideIcons.bell,
              title: 'Notifications',
              subtitle: 'Reminder settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsPage(),
                  ),
                );
              },
            ),
            _buildDivider(context),
            _buildSwitchTile(
              context,
              icon: LucideIcons.fingerprint,
              title: 'Biometric Lock',
              subtitle: 'Secure with fingerprint/face',
              value: _biometricEnabled,
              onChanged: (value) {
                setState(() => _biometricEnabled = value);
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          const SizedBox(height: 8),
          BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              final languageName = LanguageCubit.getDisplayName(locale);
              return _buildSettingsCard(context, [
                _buildPickerTile(
                  context,
                  icon: LucideIcons.globe,
                  title: 'Language',
                  value: languageName,
                  options: ['English', 'Francais'],
                  onSelected: (value) {
                    final langCode = value == 'English' ? 'en' : 'fr';
                    context.read<LanguageCubit>().setLanguageCode(langCode);
                  },
                ),
                _buildDivider(context),
                _buildPickerTile(
                  context,
                  icon: LucideIcons.palette,
                  title: 'Theme',
                  value: _selectedTheme,
                  options: ['Light', 'Dark', 'System'],
                  onSelected: (value) {
                    setState(() => _selectedTheme = value);
                  },
                ),
              ]);
            },
          ),
          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader(context, 'Data'),
          const SizedBox(height: 8),
          _buildSettingsCard(context, [
            _buildNavigationTile(
              context,
              icon: LucideIcons.download,
              title: 'Backup & Export',
              subtitle: 'Export your prayer data',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BackupPage(),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader(context, 'About'),
          const SizedBox(height: 8),
          _buildSettingsCard(context, [
            _buildNavigationTile(
              context,
              icon: LucideIcons.helpCircle,
              title: 'Help & FAQ',
              subtitle: 'Get support',
              onTap: () {
                // Show help
              },
            ),
            _buildDivider(context),
            _buildNavigationTile(
              context,
              icon: LucideIcons.fileText,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () {
                // Show privacy policy
              },
            ),
            _buildDivider(context),
            _buildNavigationTile(
              context,
              icon: LucideIcons.info,
              title: 'About Kneel',
              subtitle: 'Version 1.0.0',
              onTap: () {
                // Show about dialog
                showAboutDialog(
                  context: context,
                  applicationName: 'Kneel',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '2024 Kneel. All rights reserved.',
                );
              },
            ),
          ]),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha:0.1),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outline.withValues(alpha:0.1),
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha:0.6),
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildPickerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:0.6),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronRight,
            color: theme.colorScheme.onSurface.withValues(alpha:0.4),
          ),
        ],
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...options.map((option) => ListTile(
                      title: Text(option),
                      trailing: value == option
                          ? Icon(LucideIcons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        onSelected(option);
                        Navigator.pop(ctx);
                      },
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
