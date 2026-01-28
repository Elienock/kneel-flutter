import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_cubit.dart';
import 'package:quick_church/features/sermon/presentation/widgets/metadata_header.dart';

/// Page for creating and editing sermon notes.
class SermonEditorPage extends StatefulWidget {
  final String? noteId;
  final String? initialSeriesId;
  final String? initialSeries;

  const SermonEditorPage({
    super.key,
    this.noteId,
    this.initialSeriesId,
    this.initialSeries,
  });

  @override
  State<SermonEditorPage> createState() => _SermonEditorPageState();
}

class _SermonEditorPageState extends State<SermonEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _preacherController;
  late TextEditingController _verseController;
  late TextEditingController _tagsController;

  String? _selectedSeriesId;
  String? _selectedSeriesName;
  DateTime _selectedDate = DateTime.now();
  bool _isMetadataExpanded = true;
  bool _isNewSeries = false;
  final TextEditingController _newSeriesController = TextEditingController();

  SermonNote? _existingNote;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _preacherController = TextEditingController();
    _verseController = TextEditingController();
    _tagsController = TextEditingController();

    _selectedSeriesId = widget.initialSeriesId;
    _selectedSeriesName = widget.initialSeries;

    // Load existing note if editing
    if (widget.noteId != null) {
      _loadExistingNote();
    }

    // Add listeners for change detection
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
    _preacherController.addListener(_onChanged);
    _verseController.addListener(_onChanged);
    _tagsController.addListener(_onChanged);
  }

  void _loadExistingNote() {
    final cubit = context.read<SermonCubit>();
    _existingNote = cubit.getNoteById(widget.noteId!);

    if (_existingNote != null) {
      _titleController.text = _existingNote!.title;
      _contentController.text = _existingNote!.content;
      _preacherController.text = _existingNote!.preacher;
      _verseController.text = _existingNote!.mainVerse;
      _tagsController.text = _existingNote!.tags.join(', ');
      _selectedSeriesId = _existingNote!.seriesId;
      _selectedSeriesName = _existingNote!.seriesTitle;
      _selectedDate = _existingNote!.date;
    }
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _preacherController.dispose();
    _verseController.dispose();
    _tagsController.dispose();
    _newSeriesController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a title'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Get user ID from ProfileCubit
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is! ProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to save. Please try again.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final userId = profileState.profile.id;

    setState(() => _isSaving = true);

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final cubit = context.read<SermonCubit>();

    // If creating a new series, create it first
    String? seriesId = _selectedSeriesId;
    String? seriesName = _selectedSeriesName;
    if (_isNewSeries && _newSeriesController.text.trim().isNotEmpty) {
      final newSeriesName = _newSeriesController.text.trim();
      final series = await cubit.createSeries(title: newSeriesName);
      if (series != null) {
        seriesId = series.id;
        seriesName = series.title;
      }
    }

    final note = SermonNote(
      id: _existingNote?.id ?? '',
      userId: userId,
      seriesId: seriesId,
      title: title,
      preacher: _preacherController.text.trim().isNotEmpty
          ? _preacherController.text.trim()
          : 'Unknown',
      verse: _verseController.text.trim().isNotEmpty
          ? _verseController.text.trim()
          : null,
      content: _contentController.text.trim(),
      sermonDate: _selectedDate,
      isPinned: _existingNote?.isPinned ?? false,
      tags: tags,
      createdAt: _existingNote?.createdAt ?? DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      seriesTitle: seriesName,
    );

    await cubit.saveNote(note);

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Discard',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        appBar: AppBar(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _existingNote != null ? 'Edit Note' : 'New Note',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _saveNote,
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collapsible Metadata Header
              MetadataHeader(
                isExpanded: _isMetadataExpanded,
                onToggle: () => setState(() => _isMetadataExpanded = !_isMetadataExpanded),
                preacherController: _preacherController,
                verseController: _verseController,
                selectedDate: _selectedDate,
                onDateChanged: (date) => setState(() {
                  _selectedDate = date;
                  _hasChanges = true;
                }),
                selectedSeriesId: _selectedSeriesId,
                selectedSeriesName: _selectedSeriesName,
                isNewSeries: _isNewSeries,
                newSeriesController: _newSeriesController,
                onSeriesChanged: (id, name) => setState(() {
                  _selectedSeriesId = id;
                  _selectedSeriesName = name;
                  _isNewSeries = false;
                  _hasChanges = true;
                }),
                onNewSeries: () => setState(() {
                  _isNewSeries = true;
                  _selectedSeriesId = null;
                  _selectedSeriesName = null;
                  _hasChanges = true;
                }),
                isDark: isDark,
              ),

              // Title Field
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextField(
                  controller: _titleController,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Sermon Title',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ),

              // Tags Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _tagsController,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tags (comma separated)',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      LucideIcons.hash,
                      size: 18,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 0,
                    ),
                  ),
                ),
              ),

              const Divider(height: 32),

              // Content Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _contentController,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start writing your notes...\n\nCapture key points, insights, and applications from the sermon.',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white24 : Colors.black26,
                      height: 1.6,
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  minLines: 15,
                  keyboardType: TextInputType.multiline,
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
