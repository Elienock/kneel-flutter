import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/widgets/add_prayer_bottom_sheet.dart';

/// Bottom sheet for editing an existing prayer.
class EditPrayerBottomSheet extends StatefulWidget {
  final Prayer prayer;

  const EditPrayerBottomSheet({super.key, required this.prayer});

  static Future<void> show(BuildContext context, Prayer prayer) {
    final cubit = context.read<PrayerCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: EditPrayerBottomSheet(prayer: prayer),
      ),
    );
  }

  @override
  State<EditPrayerBottomSheet> createState() => _EditPrayerBottomSheetState();
}

class _EditPrayerBottomSheetState extends State<EditPrayerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _requesterController;
  late TextEditingController _scriptureController;
  late TextEditingController _testimonyController;

  late PrayerPriority _priority;
  late PrayerCategory _category;
  late bool _isLocked;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.prayer.title);
    _descriptionController = TextEditingController(text: widget.prayer.description);
    _requesterController = TextEditingController(text: widget.prayer.requesterName ?? '');
    _scriptureController = TextEditingController(text: widget.prayer.scriptureReference ?? '');
    _testimonyController = TextEditingController(text: widget.prayer.testimony ?? '');
    _priority = widget.prayer.priority;
    _isLocked = widget.prayer.isLocked;

    // Determine category from tags
    _category = PrayerCategory.personal;
    for (final tag in widget.prayer.tags) {
      try {
        _category = PrayerCategory.values.firstWhere(
          (c) => c.name.toLowerCase() == tag.toLowerCase(),
        );
        break;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requesterController.dispose();
    _scriptureController.dispose();
    _testimonyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isAnswered = widget.prayer.status == PrayerStatus.answered;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
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
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withAlpha(77),
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
                        child: const Icon(
                          LucideIcons.pencil,
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
                              'Edit Prayer',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              'Update your prayer request',
                              style: theme.textTheme.bodySmall,
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
                    decoration: const InputDecoration(
                      labelText: 'Prayer Title',
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

                  // Category selection
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
                      return ChoiceChip(
                        label: Text(category.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _category = category);
                          }
                        },
                        avatar: Icon(
                          category.icon,
                          size: 18,
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
                              : theme.colorScheme.outline,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Priority selection
                  Text(
                    'Priority',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<PrayerPriority>(
                    segments: PrayerPriority.values.map((priority) {
                      return ButtonSegment(
                        value: priority,
                        label: Text(priority.name.toUpperCase()),
                        icon: Icon(_getPriorityIcon(priority), size: 16),
                      );
                    }).toList(),
                    selected: {_priority},
                    onSelectionChanged: (selection) {
                      setState(() => _priority = selection.first);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
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

                  // Scripture reference field
                  TextFormField(
                    controller: _scriptureController,
                    decoration: const InputDecoration(
                      labelText: 'Scripture Reference (optional)',
                      hintText: 'e.g., Philippians 4:6',
                      prefixIcon: Icon(LucideIcons.bookOpen),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Testimony field (only if answered)
                  if (isAnswered) ...[
                    TextFormField(
                      controller: _testimonyController,
                      decoration: const InputDecoration(
                        labelText: 'Testimony (optional)',
                        hintText: 'How did God answer this prayer?',
                        prefixIcon: Icon(LucideIcons.sparkles),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Requester name field
                  TextFormField(
                    controller: _requesterController,
                    decoration: const InputDecoration(
                      labelText: 'Requester Name (optional)',
                      prefixIcon: Icon(LucideIcons.user),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Lock toggle
                  _buildToggle(
                    context,
                    icon: _isLocked ? LucideIcons.lock : LucideIcons.unlock,
                    label: 'Lock Prayer',
                    subtitle: 'Require PIN to view details',
                    value: _isLocked,
                    onChanged: (value) => setState(() => _isLocked = value),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveForm,
                    icon: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.checkCircle),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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
    );
  }

  Widget _buildToggle(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
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

  void _saveForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      final updatedPrayer = widget.prayer.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        requesterName: _requesterController.text.trim().isEmpty
            ? null
            : _requesterController.text.trim(),
        scriptureReference: _scriptureController.text.trim().isEmpty
            ? null
            : _scriptureController.text.trim(),
        testimony: _testimonyController.text.trim().isEmpty
            ? null
            : _testimonyController.text.trim(),
        priority: _priority,
        isLocked: _isLocked,
        tags: [_category.name],
        updatedAt: DateTime.now(),
      );

      context.read<PrayerCubit>().updatePrayer(updatedPrayer);
      Navigator.of(context).pop();
    }
  }
}
