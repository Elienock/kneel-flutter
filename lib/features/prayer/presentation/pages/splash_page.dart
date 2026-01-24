import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';

/// Custom splash screen with "Kneel" branding and "from Claudine Tech" footer.
class SplashPage extends StatelessWidget {
  final VoidCallback onInitComplete;

  const SplashPage({super.key, required this.onInitComplete});

  @override
  Widget build(BuildContext context) {
    // Trigger navigation after a delay
    Future.delayed(const Duration(milliseconds: 1500), onInitComplete);

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Center content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to heart icon if image fails
                        return const Icon(
                          LucideIcons.heart,
                          size: 50,
                          color: AppTheme.primaryColor,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // App Name
                Text(
                  'Kneel',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                Text(
                  'Your Personal Prayer Companion',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ],
            ),
            const Spacer(flex: 2),
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'from ',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withAlpha(153),
                    ),
                  ),
                  Text(
                    'Claudine Tech',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
