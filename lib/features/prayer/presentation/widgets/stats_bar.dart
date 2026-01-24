import 'package:flutter/material.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';

/// A horizontal bar displaying prayer statistics.
class StatsBar extends StatelessWidget {
  final List<Prayer> prayers;

  const StatsBar({super.key, required this.prayers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalPrayers = prayers.length;
    final answeredPrayers = prayers.where((p) => p.status == PrayerStatus.answered).length;
    final activePrayers = prayers.where((p) => p.status == PrayerStatus.active).length;
    final urgentPrayers = prayers.where((p) => p.priority == PrayerPriority.urgent).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatChip(
            icon: Icons.format_list_numbered,
            label: 'Total',
            value: totalPrayers.toString(),
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.check_circle,
            label: 'Answered',
            value: answeredPrayers.toString(),
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.pending,
            label: 'Active',
            value: activePrayers.toString(),
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.priority_high,
            label: 'Urgent',
            value: urgentPrayers.toString(),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(51),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withAlpha(204),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
