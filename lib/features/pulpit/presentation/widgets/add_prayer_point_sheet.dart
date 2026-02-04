import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/pulpit/domain/entities/pulpit_prayer_group.dart';
import 'package:quick_church/features/pulpit/presentation/bloc/pulpit_cubit.dart';

/// Bottom sheet for adding or editing a prayer point.
class AddPrayerPointSheet extends StatefulWidget {
  final PulpitPrayerPoint? point;

  const AddPrayerPointSheet({super.key, this.point});

  static Future<void> show(BuildContext context, {PulpitPrayerPoint? point}) async {
    final cubit = context.read<PulpitCubit>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: AddPrayerPointSheet(point: point),
      ),
    );
  }

  @override
  State<AddPrayerPointSheet> createState() => _AddPrayerPointSheetState();
}

class _AddPrayerPointSheetState extends State<AddPrayerPointSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<ScriptureEntry> _scriptures = [];
  bool _isSaving = false;

  bool get _isEditing => widget.point != null;

  @override
  void initState() {
    super.initState();
    if (widget.point != null) {
      _titleController.text = widget.point!.title;
      _descriptionController.text = widget.point!.description ?? '';
      _scriptures.addAll(
        widget.point!.scriptures.map((s) => ScriptureEntry(
          referenceController: TextEditingController(text: s.reference),
          textController: TextEditingController(text: s.text ?? ''),
        )),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final s in _scriptures) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isEditing ? LucideIcons.pencil : LucideIcons.plus,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit Prayer Point' : 'Add Prayer Point',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Include title, description, and scriptures',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Prayer Title *',
                      hintText: 'e.g., Pray for the Youth',
                      prefixIcon: const Icon(LucideIcons.heart),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description / Talking Points',
                      hintText: 'Key points to cover during this prayer',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(LucideIcons.alignLeft),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),

                  // Scriptures Section
                  Row(
                    children: [
                      const Icon(LucideIcons.bookOpen, color: AppTheme.secondaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Scripture References',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addScripture,
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_scriptures.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 18,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add scriptures to display during the session',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._scriptures.asMap().entries.map((entry) {
                      return _buildScriptureField(entry.key, entry.value, isDark);
                    }),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_isEditing ? LucideIcons.check : LucideIcons.plus),
                      label: Text(_isSaving
                          ? 'Saving...'
                          : (_isEditing ? 'Update Point' : 'Add Point')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  // Delete Button (for editing)
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _delete,
                        icon: const Icon(LucideIcons.trash2),
                        label: const Text('Delete Point'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.urgentColor,
                          side: const BorderSide(color: AppTheme.urgentColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptureField(int index, ScriptureEntry entry, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.referenceController,
                  decoration: InputDecoration(
                    labelText: 'Reference',
                    hintText: 'e.g., John 3:16',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => _removeScripture(index),
                tooltip: 'Remove',
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: entry.textController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Verse Text (optional)',
              hintText: 'Paste the scripture text here',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addScripture() {
    HapticFeedback.selectionClick();
    setState(() {
      _scriptures.add(ScriptureEntry(
        referenceController: TextEditingController(),
        textController: TextEditingController(),
      ));
    });
  }

  void _removeScripture(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _scriptures[index].dispose();
      _scriptures.removeAt(index);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a prayer title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Build scripture list
    final scriptures = _scriptures
        .where((s) => s.referenceController.text.trim().isNotEmpty)
        .map((s) => ScriptureReference(
              reference: s.referenceController.text.trim(),
              text: s.textController.text.trim().isEmpty
                  ? null
                  : s.textController.text.trim(),
            ))
        .toList();

    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    try {
      if (_isEditing) {
        final updated = widget.point!.copyWith(
          title: title,
          description: description,
          scriptures: scriptures,
        );
        await context.read<PulpitCubit>().updatePoint(updated);
      } else {
        await context.read<PulpitCubit>().addPoint(
              title: title,
              description: description,
              scriptures: scriptures,
            );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Prayer Point?'),
        content: Text('Delete "${widget.point!.title}"?'),
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

    if (confirmed == true && mounted) {
      await context.read<PulpitCubit>().deletePoint(widget.point!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

/// Helper class to manage scripture entry controllers.
class ScriptureEntry {
  final TextEditingController referenceController;
  final TextEditingController textController;

  ScriptureEntry({
    required this.referenceController,
    required this.textController,
  });

  void dispose() {
    referenceController.dispose();
    textController.dispose();
  }
}
