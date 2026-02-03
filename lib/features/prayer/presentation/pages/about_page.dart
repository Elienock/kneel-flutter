import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/core/widgets/kneel_logo.dart';

/// About page displaying app information, developer credits, and roadmap.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header Card
            _buildAppHeaderCard(context),
            const SizedBox(height: 24),

            // Developer Section
            Text(
              'Developer',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildDeveloperTile(context),
            const SizedBox(height: 24),

            // Roadmap Section
            Text(
              'Roadmap',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildRoadmapCard(context),
            const SizedBox(height: 24),

            // Legal Section
            Text(
              'Legal',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildLegalTiles(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF1C1C1E),
                  Color(0xFF2C2C2E),
                ]
              : const [
                  Color(0xFFF8F8F8),
                  Color(0xFFFFFFFF),
                ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 13),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Official Kneel Logo - Dark variant with elevation for About page
          KneelLogo.dark(
            height: 80,
            showElevation: true,
            elevation: 8,
            shadowColor: AppTheme.primaryColor.withAlpha(102),
          ),
          const SizedBox(height: 16),
          Text(
            'Kneel',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'v1.0.0',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your Personal Prayer Companion',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF636366),
            ),
          ),
          const SizedBox(height: 16),
          // Branding footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'from ',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                ),
              ),
              Text(
                'Claudine Tech',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperTile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.user,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          'Elienock Lubaya Mulumba',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Lead Developer',
          style: GoogleFonts.inter(color: const Color(0xFF8E8E93)),
        ),
        trailing: const Icon(
          LucideIcons.badgeCheck,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildRoadmapCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roadmapItems = [
      ('Cloud Sync', LucideIcons.cloudCog, 'Sync prayers across devices'),
      ('Sermon Notes', LucideIcons.bookOpen, 'Take notes during sermons'),
      ('Daily Reminders', LucideIcons.bell, 'Prayer time notifications'),
      ('Community', LucideIcons.users, 'Share prayers with your church'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.rocket,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Coming Soon',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This is v1. We\'re actively building new features to enhance your spiritual journey.',
              style: GoogleFonts.inter(
                color: const Color(0xFF8E8E93),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ...roadmapItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.$2,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item.$3,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalTiles(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.fileText),
            title: Text('Licenses', style: GoogleFonts.inter()),
            trailing: const Icon(LucideIcons.chevronRight, size: 20),
            onTap: () => _showLicenses(context),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
          ListTile(
            leading: const Icon(LucideIcons.shield),
            title: Text('Privacy Policy', style: GoogleFonts.inter()),
            trailing: const Icon(LucideIcons.chevronRight, size: 20),
            onTap: () => _showPrivacyPolicy(context),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA)),
          ListTile(
            leading: const Icon(LucideIcons.scroll),
            title: Text('Terms of Service', style: GoogleFonts.inter()),
            trailing: const Icon(LucideIcons.chevronRight, size: 20),
            onTap: () => _showTerms(context),
          ),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Kneel',
      applicationVersion: 'v1.0.0',
      applicationIcon: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.heart,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
      applicationLegalese: '2026 Elienock Lubaya Mulumba\nMIT License',
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
        ),
        title: Text('Privacy Policy', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(
            'Kneel respects your privacy.\n\n'
            'All prayer data is stored locally on your device.\n'
            'We do not collect or transmit personal information.\n'
            'No analytics or tracking is implemented.\n'
            'Your spiritual journey remains private.\n\n'
            'For questions, contact the developer.',
            style: GoogleFonts.inter(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.dialogRadius),
        ),
        title: Text('Terms of Service', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(
            'By using Kneel, you agree to:\n\n'
            'Use the app for personal spiritual growth.\n'
            'Not misuse the app for harmful purposes.\n'
            'Accept that the app is provided "as is".\n\n'
            'This app is open source under the MIT License.',
            style: GoogleFonts.inter(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
