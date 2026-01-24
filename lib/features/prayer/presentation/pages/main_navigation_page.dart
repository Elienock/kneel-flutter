import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/presentation/pages/calendar_page.dart';
import 'package:quick_church/features/prayer/presentation/pages/faithfulness_page.dart';
import 'package:quick_church/features/prayer/presentation/pages/focus_page.dart';
import 'package:quick_church/features/prayer/presentation/pages/home_page.dart';
import 'package:quick_church/features/prayer/presentation/pages/prayers_page.dart';
import 'package:quick_church/features/prayer/presentation/widgets/add_prayer_bottom_sheet.dart';

/// Main navigation shell with YouVersion-style bottom navigation.
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  // Page storage bucket to preserve scroll positions
  final PageStorageBucket _bucket = PageStorageBucket();

  // Navigation items with Lucide icons (modern outline look)
  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: LucideIcons.home,
      selectedIcon: LucideIcons.home,
      label: 'Home',
    ),
    _NavItem(
      icon: LucideIcons.heart,
      selectedIcon: LucideIcons.heart,
      label: 'Prayers',
    ),
    _NavItem(
      icon: LucideIcons.calendar,
      selectedIcon: LucideIcons.calendar,
      label: 'Calendar',
    ),
    _NavItem(
      icon: LucideIcons.crosshair,
      selectedIcon: LucideIcons.crosshair,
      label: 'Focus',
    ),
    _NavItem(
      icon: LucideIcons.sparkles,
      selectedIcon: LucideIcons.sparkles,
      label: 'Testimonies',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Update system UI based on current theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark
          ? AppTheme.darkSurface
          : AppTheme.cardBackground,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomePage(
              key: const PageStorageKey('home'),
              onNavigateToPrayers: () => setState(() => _currentIndex = 1),
            ),
            const PrayersPage(key: PageStorageKey('prayers')),
            const CalendarPage(key: PageStorageKey('calendar')),
            const FocusPage(key: PageStorageKey('focus')),
            const FaithfulnessPage(key: PageStorageKey('testimonies')),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => AddPrayerBottomSheet.show(context),
              icon: Icon(LucideIcons.plus),
              label: const Text('New Prayer'),
            )
          : null,
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppTheme.darkSurface
        : AppTheme.cardBackground;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 13),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;

              return _NavItemWidget(
                item: item,
                isSelected: isSelected,
                onTap: () => setState(() => _currentIndex = index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Navigation item data class.
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Individual navigation item widget with animation.
class _NavItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final unselectedColor = const Color(0xFF8E8E93);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white.withAlpha(26) : const Color(0xFFF2F2F7))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
