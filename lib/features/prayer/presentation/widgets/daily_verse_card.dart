import 'package:flutter/material.dart';
import 'package:quick_church/core/theme/app_theme.dart';

/// A beautiful card displaying the verse of the day - YouVersion style.
class DailyVerseCard extends StatelessWidget {
  const DailyVerseCard({super.key});

  // Sample verses - in production, this could come from an API
  static const List<Map<String, String>> _verses = [
    {
      'verse': 'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.',
      'reference': 'Philippians 4:6',
    },
    {
      'verse': 'The Lord is near to all who call on him, to all who call on him in truth.',
      'reference': 'Psalm 145:18',
    },
    {
      'verse': 'Come to me, all you who are weary and burdened, and I will give you rest.',
      'reference': 'Matthew 11:28',
    },
    {
      'verse': 'Trust in the Lord with all your heart and lean not on your own understanding.',
      'reference': 'Proverbs 3:5',
    },
    {
      'verse': 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you.',
      'reference': 'Jeremiah 29:11',
    },
    {
      'verse': 'Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you.',
      'reference': 'Joshua 1:9',
    },
    {
      'verse': 'The Lord is my shepherd; I shall not want.',
      'reference': 'Psalm 23:1',
    },
    {
      'verse': 'I can do all things through Christ who strengthens me.',
      'reference': 'Philippians 4:13',
    },
    {
      'verse': 'Cast all your anxiety on him because he cares for you.',
      'reference': '1 Peter 5:7',
    },
    {
      'verse': 'The Lord is my light and my salvation—whom shall I fear?',
      'reference': 'Psalm 27:1',
    },
  ];

  Map<String, String> get _todaysVerse {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _verses[dayOfYear % _verses.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final verse = _todaysVerse;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 77 : 20),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: Color(0xFF007AFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verse of the Day',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _getFormattedDate(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: theme.colorScheme.outline,
                  size: 20,
                ),
                onPressed: () {
                  // TODO: Implement share
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Verse text with quote marks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF007AFF).withAlpha(77),
                  height: 0.8,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  verse['verse']!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reference
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    verse['reference']!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
