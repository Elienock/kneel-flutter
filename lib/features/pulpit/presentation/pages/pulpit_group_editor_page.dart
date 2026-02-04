import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/pulpit/domain/entities/pulpit_prayer_group.dart';
import 'package:quick_church/features/pulpit/presentation/bloc/pulpit_cubit.dart';
import 'package:quick_church/features/pulpit/presentation/bloc/pulpit_state.dart';
import 'package:quick_church/features/pulpit/presentation/widgets/add_prayer_point_sheet.dart';
import 'package:quick_church/features/pulpit/presentation/pages/pulpit_session_page.dart';

/// Page for creating/editing a pulpit prayer group and its points.
class PulpitGroupEditorPage extends StatefulWidget {
  final String? groupId;

  const PulpitGroupEditorPage({super.key, this.groupId});

  @override
  State<PulpitGroupEditorPage> createState() => _PulpitGroupEditorPageState();
}

class _PulpitGroupEditorPageState extends State<PulpitGroupEditorPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _autoAdvance = false;
  int _secondsPerPoint = 300; // 5 minutes default
  bool _isNewGroup = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isNewGroup = widget.groupId == null;
    if (!_isNewGroup) {
      _loadGroup();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadGroup() async {
    final group = await context.read<PulpitCubit>().loadGroupWithPoints(widget.groupId!);
    if (group != null && mounted) {
      setState(() {
        _titleController.text = group.title;
        _descriptionController.text = group.description ?? '';
        _autoAdvance = group.autoAdvance;
        _secondsPerPoint = group.secondsPerPoint;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          _isNewGroup ? 'New Prayer Group' : 'Edit Prayer Group',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isNewGroup)
            BlocBuilder<PulpitCubit, PulpitState>(
              builder: (context, state) {
                final hasPoints = (state.selectedGroup?.points.length ?? 0) > 0;
                return IconButton(
                  icon: const Icon(LucideIcons.play),
                  onPressed: hasPoints ? () => _startSession(context) : null,
                  tooltip: 'Start Session',
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Details Card
                  _buildGroupDetailsCard(isDark),
                  const SizedBox(height: 24),

                  // Timer Settings Card
                  _buildTimerSettingsCard(isDark),
                  const SizedBox(height: 24),

                  // Save Button (for new groups)
                  if (_isNewGroup) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveGroup,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.save),
                        label: Text(_isSaving ? 'Creating...' : 'Create Group'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Prayer Points Section (only for existing groups)
                  if (!_isNewGroup) ...[
                    _buildPrayerPointsSection(isDark),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildGroupDetailsCard(bool isDark) {
    return Card(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.fileText, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Group Details',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Group Title',
                hintText: 'e.g., Sunday Morning Intercession',
                prefixIcon: const Icon(LucideIcons.type),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _autoSaveIfEditing(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description of this prayer session',
                prefixIcon: const Icon(LucideIcons.alignLeft),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _autoSaveIfEditing(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSettingsCard(bool isDark) {
    return Card(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.timer, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Timer Settings',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Auto-Advance'),
              subtitle: Text(
                _autoAdvance
                    ? 'Automatically move to next prayer point'
                    : 'Manually control when to move to next point',
              ),
              value: _autoAdvance,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _autoAdvance = value);
                _autoSaveIfEditing();
              },
              activeColor: AppTheme.primaryColor,
            ),
            if (_autoAdvance) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Time per Prayer Point',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PulpitTimerPreset.values
                    .where((p) => !p.isManual)
                    .map((preset) {
                  final isSelected = _secondsPerPoint == preset.seconds;
                  return ChoiceChip(
                    label: Text(preset.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        setState(() => _secondsPerPoint = preset.seconds);
                        _autoSaveIfEditing();
                      }
                    },
                    selectedColor: AppTheme.primaryColor.withAlpha(40),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerPointsSection(bool isDark) {
    return BlocBuilder<PulpitCubit, PulpitState>(
      builder: (context, state) {
        final points = state.selectedGroup?.points ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.list, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Prayer Points',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _addPrayerPoint(context),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (points.isEmpty)
              _buildEmptyPointsState(isDark)
            else
              _buildPointsList(points, isDark),
          ],
        );
      },
    );
  }

  Widget _buildEmptyPointsState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.listPlus,
            size: 48,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'No prayer points yet',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add prayer points to structure your pulpit session',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsList(List<PulpitPrayerPoint> points, bool isDark) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: points.length,
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        context.read<PulpitCubit>().reorderPoints(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final point = points[index];
        return _PrayerPointCard(
          key: ValueKey(point.id),
          point: point,
          index: index,
          isDark: isDark,
          onEdit: () => _editPrayerPoint(context, point),
          onDelete: () => _deletePrayerPoint(context, point),
        );
      },
    );
  }

  Future<void> _saveGroup() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final group = await context.read<PulpitCubit>().createGroup(
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          autoAdvance: _autoAdvance,
          secondsPerPoint: _autoAdvance ? _secondsPerPoint : 0,
        );

    setState(() => _isSaving = false);

    if (group != null && mounted) {
      // Navigate to edit mode with the new group
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => BlocProvider.value(
            value: context.read<PulpitCubit>(),
            child: PulpitGroupEditorPage(groupId: group.id),
          ),
        ),
      );
    }
  }

  void _autoSaveIfEditing() {
    if (!_isNewGroup) {
      // Debounced auto-save could be implemented here
      // For now, we'll save on specific actions
    }
  }

  Future<void> _updateGroupSettings() async {
    final state = context.read<PulpitCubit>().state;
    if (state.selectedGroup == null) return;

    final updated = state.selectedGroup!.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      autoAdvance: _autoAdvance,
      secondsPerPoint: _autoAdvance ? _secondsPerPoint : 0,
    );

    await context.read<PulpitCubit>().updateGroup(updated);
  }

  Future<void> _addPrayerPoint(BuildContext context) async {
    HapticFeedback.mediumImpact();

    // Save current settings first
    await _updateGroupSettings();

    if (!mounted) return;

    await AddPrayerPointSheet.show(context);
  }

  Future<void> _editPrayerPoint(BuildContext context, PulpitPrayerPoint point) async {
    HapticFeedback.selectionClick();
    await AddPrayerPointSheet.show(context, point: point);
  }

  Future<void> _deletePrayerPoint(BuildContext context, PulpitPrayerPoint point) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Prayer Point?'),
        content: Text('Delete "${point.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.urgentColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<PulpitCubit>().deletePoint(point.id);
    }
  }

  Future<void> _startSession(BuildContext context) async {
    // Save settings first
    await _updateGroupSettings();

    final state = context.read<PulpitCubit>().state;
    if (state.selectedGroup == null || state.selectedGroup!.points.isEmpty) {
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => BlocProvider.value(
            value: context.read<PulpitCubit>(),
            child: PulpitSessionPage(group: state.selectedGroup!),
          ),
        ),
      );
    }
  }
}

/// Card widget for a prayer point in the list.
class _PrayerPointCard extends StatelessWidget {
  final PulpitPrayerPoint point;
  final int index;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PrayerPointCard({
    super.key,
    required this.point,
    required this.index,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        title: Text(
          point.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
        subtitle: point.scriptures.isNotEmpty
            ? Text(
                point.scriptures.map((s) => s.reference).join(', '),
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : (point.description != null
                ? Text(
                    point.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 18),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(LucideIcons.gripVertical),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
