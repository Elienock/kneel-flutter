import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';

/// Modern bottom sheet for adding a new prayer request.
class AddPrayerBottomSheet extends StatefulWidget {
  const AddPrayerBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = context.read<PrayerCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: const AddPrayerBottomSheet(),
      ),
    );
  }

  @override
  State<AddPrayerBottomSheet> createState() => _AddPrayerBottomSheetState();
}

class _AddPrayerBottomSheetState extends State<AddPrayerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  PrayerPriority _priority = PrayerPriority.medium;
  PrayerCategory _category = PrayerCategory.personal;
  bool _isLocked = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar for drag indication
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withAlpha(102),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            LucideIcons.plusCircle,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Prayer Request',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Share your heart with God',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Prayer Title',
                        hintText: 'e.g., Family Health, Job Interview',
                        prefixIcon: Icon(LucideIcons.type),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category selection - No tick icon, only background color toggle
                    Text(
                      'Category',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PrayerCategory.values.map((category) {
                        final isSelected = _category == category;
                        return GestureDetector(
                          onTap: () => setState(() => _category = category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withAlpha(26)
                                  : isDark
                                      ? const Color(0xFF2A2A2A)
                                      : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category.icon,
                                  size: 16,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  category.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Priority selection - Using Wrap with compact chips
                    Text(
                      'Priority',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PrayerPriority.values.map((priority) {
                        final isSelected = _priority == priority;
                        final (color, label) = switch (priority) {
                          PrayerPriority.low => (AppTheme.lowColor, 'Low'),
                          PrayerPriority.medium => (AppTheme.mediumColor, 'Medium'),
                          PrayerPriority.high => (AppTheme.highColor, 'High'),
                          PrayerPriority.urgent => (AppTheme.urgentColor, 'Urgent'),
                        };
                        return GestureDetector(
                          onTap: () => setState(() => _priority = priority),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withAlpha(26)
                                  : isDark
                                      ? const Color(0xFF2A2A2A)
                                      : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? color : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getPriorityIcon(priority),
                                  size: 14,
                                  color: isSelected ? color : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? color : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Share more details about your prayer...',
                        prefixIcon: Icon(LucideIcons.alignLeft),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lock toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isLocked ? LucideIcons.lock : LucideIcons.unlock,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lock Prayer',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Require PIN to view details',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isLocked,
                            onChanged: (value) {
                              setState(() => _isLocked = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submitForm,
                      icon: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Icon(LucideIcons.checkCircle),
                      label: Text(_isSubmitting ? 'Adding Prayer...' : 'Add to Prayer Wall'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getPriorityIcon(PrayerPriority priority) {
    return switch (priority) {
      PrayerPriority.low => LucideIcons.arrowDown,
      PrayerPriority.medium => LucideIcons.minus,
      PrayerPriority.high => LucideIcons.arrowUp,
      PrayerPriority.urgent => LucideIcons.alertTriangle,
    };
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSubmitting = true);

      context.read<PrayerCubit>().addPrayer(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            priority: _priority,
            isLocked: _isLocked,
            tags: [_category.name],
          );

      Navigator.of(context).pop();
    }
  }
}

/// Prayer category for organization.
enum PrayerCategory {
  personal(LucideIcons.user, 'Personal'),
  family(LucideIcons.users, 'Family'),
  health(LucideIcons.heartPulse, 'Health'),
  work(LucideIcons.briefcase, 'Work'),
  church(LucideIcons.church, 'Church'),
  urgent(LucideIcons.alertTriangle, 'Urgent');

  final IconData icon;
  final String label;

  const PrayerCategory(this.icon, this.label);
}
