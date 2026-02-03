import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_cubit.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_state.dart';

/// Premium iOS-style Rich Text Canvas for sermon notes.
/// Features:
/// - Full-screen clean layout with borderless title
/// - flutter_quill for rich text editing (H1, H2, Bold, Italic, Bullet Points)
/// - Floating formatting toolbar (visible with keyboard)
/// - Auto-save with 2-second debouncer ("Ghost Save")
/// - Collapsible metadata chips for Speaker & Bible Reference
/// - onPopInvoked triggers final sync
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
  // Controllers
  late TextEditingController _titleController;
  late QuillController _quillController;
  late ScrollController _scrollController;
  late FocusNode _titleFocusNode;
  late FocusNode _editorFocusNode;

  // Metadata
  String _preacher = '';
  String _verse = '';
  String? _selectedSeriesId;
  String? _selectedSeriesName;
  DateTime _selectedDate = DateTime.now();
  List<String> _tags = [];

  // State
  SermonNote? _existingNote;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  bool _showSavedIndicator = false;
  bool _isPublic = false; // Community feature toggle

  // Auto-save debouncer (2 seconds)
  Timer? _autoSaveTimer;
  static const _autoSaveDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _quillController = QuillController.basic();
    _scrollController = ScrollController();
    _titleFocusNode = FocusNode();
    _editorFocusNode = FocusNode();

    _selectedSeriesId = widget.initialSeriesId;
    _selectedSeriesName = widget.initialSeries;

    // Load existing note if editing
    if (widget.noteId != null) {
      _loadExistingNote();
    } else {
      // Focus title for new notes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }

    // Listen for changes
    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);
  }

  void _loadExistingNote() {
    final cubit = context.read<SermonCubit>();
    _existingNote = cubit.getNoteById(widget.noteId!);

    if (_existingNote != null) {
      _titleController.text = _existingNote!.title;
      _preacher = _existingNote!.preacher;
      _verse = _existingNote!.verse ?? '';
      _selectedSeriesId = _existingNote!.seriesId;
      _selectedSeriesName = _existingNote!.seriesTitle;
      _selectedDate = _existingNote!.sermonDate;
      _tags = List.from(_existingNote!.tags);

      // Load rich text content
      _loadQuillContent(_existingNote!.content);
    }
  }

  void _loadQuillContent(String content) {
    // Handle empty or null-like content - create fresh empty document
    if (content.isEmpty || content.trim().isEmpty) {
      debugPrint('SermonEditor: Empty content, using default empty document');
      _initEmptyQuillController();
      return;
    }

    debugPrint('SermonEditor: Loading content, length=${content.length}');

    try {
      // Try to parse as JSON (rich text Delta format)
      if (content.trimLeft().startsWith('[')) {
        // Sanitize the JSON string by removing control characters
        // Keep \n and \t but remove other control chars
        final sanitized = content.replaceAll(
          RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
          '',
        );

        final json = jsonDecode(sanitized) as List<dynamic>;

        // Validate the delta has content
        if (json.isEmpty) {
          debugPrint('SermonEditor: Empty delta array, using default');
          _initEmptyQuillController();
          return;
        }

        final sanitizedJson = _sanitizeDelta(json);
        _quillController = QuillController(
          document: Document.fromJson(sanitizedJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
        _quillController.addListener(_onContentChanged);
        debugPrint('SermonEditor: Successfully loaded rich text content');
        return;
      }
    } catch (e) {
      debugPrint('SermonEditor: Failed to parse Quill JSON: $e');
      // Fall through to plain text handling
    }

    // Fallback: treat as plain text
    try {
      final sanitizedContent = content.replaceAll(
        RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
        '',
      );

      if (sanitizedContent.isNotEmpty) {
        final doc = Document();
        doc.insert(0, sanitizedContent);
        _quillController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
        _quillController.addListener(_onContentChanged);
      } else {
        _initEmptyQuillController();
      }
    } catch (e) {
      debugPrint('SermonEditor: Plain text fallback failed: $e');
      _initEmptyQuillController();
    }
  }

  /// Creates a fresh empty QuillController safely
  void _initEmptyQuillController() {
    _quillController = QuillController.basic();
    _quillController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, _performAutoSave);
  }

  Future<void> _performAutoSave() async {
    if (!_hasUnsavedChanges) return;
    if (_isSaving) return; // Prevent concurrent saves
    if (_titleController.text.trim().isEmpty) return;

    await _saveNote(showIndicator: true);
  }

  Future<void> _saveNote({bool showIndicator = false}) async {
    if (_isSaving) return; // Prevent concurrent saves

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    // Get user ID
    final profileState = context.read<ProfileCubit>().state;
    String? userId;
    if (profileState is ProfileLoaded) {
      userId = profileState.profile.id;
    } else if (profileState is ProfileNeedsOnboarding) {
      userId = profileState.profile.id;
    }

    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      // Serialize rich text content as JSON with error handling
      String contentJson;
      try {
        final delta = _quillController.document.toDelta().toJson();
        // Sanitize delta to remove problematic control characters
        final sanitizedDelta = _sanitizeDelta(delta);
        contentJson = jsonEncode(sanitizedDelta);
      } catch (e) {
        // Fallback: save as plain text if JSON encoding fails
        debugPrint('JSON encode failed, saving as plain text: $e');
        contentJson = _quillController.document.toPlainText()
            .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), ''); // Remove control chars
      }

      final note = SermonNote(
        id: _existingNote?.id ?? '',
        userId: userId,
        seriesId: _selectedSeriesId,
        title: title,
        preacher: _preacher.isNotEmpty ? _preacher : 'Unknown',
        verse: _verse.isNotEmpty ? _verse : null,
        content: contentJson,
        sermonDate: _selectedDate,
        isPinned: _existingNote?.isPinned ?? false,
        tags: _tags,
        createdAt: _existingNote?.createdAt ?? DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        seriesTitle: _selectedSeriesName,
      );

      final savedNote = await context.read<SermonCubit>().saveNote(note);

      if (savedNote != null && _existingNote == null) {
        _existingNote = savedNote;
      }

      _hasUnsavedChanges = false;

      if (showIndicator && mounted) {
        setState(() => _showSavedIndicator = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showSavedIndicator = false);
        });
      }
    } catch (e) {
      debugPrint('Save note error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _finalSaveAndPop() async {
    if (_hasUnsavedChanges && _titleController.text.trim().isNotEmpty) {
      await _saveNote();
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    _scrollController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _finalSaveAndPop();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Column(
            children: [
              // Premium Header
              _buildHeader(isDark),

              // Collapsible Metadata Chips
              _buildMetadataChips(isDark),

              // Rich Text Canvas
              Expanded(
                child: _buildRichTextCanvas(isDark),
              ),

              // Floating Formatting Toolbar
              if (bottomPadding > 0) _buildFormattingToolbar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: _finalSaveAndPop,
            icon: Icon(
              LucideIcons.chevronLeft,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 28,
            ),
          ),

          const Spacer(),

          // Save Status Indicator
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSaving
                ? Row(
                    key: const ValueKey('saving'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            isDark ? Colors.white54 : Colors.black38,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saving...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black38,
                        ),
                      ),
                    ],
                  )
                : _showSavedIndicator
                    ? Row(
                        key: const ValueKey('saved'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.cloud,
                            size: 16,
                            color: AppTheme.secondaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Saved',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
          ),

          const SizedBox(width: 12),

          // More Options
          IconButton(
            onPressed: () => _showMoreOptions(isDark),
            icon: Icon(
              LucideIcons.moreHorizontal,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildMetadataChips(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chip Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Speaker Chip
                _buildMetadataChip(
                  icon: LucideIcons.mic2,
                  label: _preacher.isNotEmpty ? _preacher : 'Speaker',
                  isSet: _preacher.isNotEmpty,
                  isDark: isDark,
                  onTap: () => _showSpeakerDialog(isDark),
                ),
                const SizedBox(width: 10),

                // Verse Chip
                _buildMetadataChip(
                  icon: LucideIcons.bookOpen,
                  label: _verse.isNotEmpty ? _verse : 'Bible Ref',
                  isSet: _verse.isNotEmpty,
                  isDark: isDark,
                  onTap: () => _showVerseDialog(isDark),
                ),
                const SizedBox(width: 10),

                // Date Chip
                _buildMetadataChip(
                  icon: LucideIcons.calendar,
                  label: _formatDateShort(_selectedDate),
                  isSet: true,
                  isDark: isDark,
                  onTap: () => _showDatePicker(isDark),
                ),
                const SizedBox(width: 10),

                // Series Chip
                _buildMetadataChip(
                  icon: LucideIcons.folder,
                  label: _selectedSeriesName ?? 'Series',
                  isSet: _selectedSeriesName != null,
                  isDark: isDark,
                  onTap: () => _showSeriesSelector(isDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required bool isSet,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSet
              ? AppTheme.primaryColor.withAlpha(isDark ? 40 : 25)
              : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSet
                ? AppTheme.primaryColor.withAlpha(60)
                : (isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSet
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSet ? FontWeight.w500 : FontWeight.normal,
                color: isSet
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichTextCanvas(bool isDark) {
    return GestureDetector(
      onTap: () => _editorFocusNode.requestFocus(),
      child: Container(
        color: Colors.transparent,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Large Borderless Title with expanded height
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.4,
                  letterSpacing: -0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Sermon Title',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white.withAlpha(50) : Colors.black.withAlpha(50),
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                maxLines: null, // Allows vertical expansion for long titles
                minLines: 1,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _editorFocusNode.requestFocus(),
              ),

              const SizedBox(height: 20),

              // Rich Text Editor with proper padding
              QuillEditor(
                controller: _quillController,
                focusNode: _editorFocusNode,
                scrollController: ScrollController(),
                config: QuillEditorConfig(
                  placeholder: 'Start capturing your sermon notes...',
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  autoFocus: false,
                  expands: false,
                  scrollable: false,
                  customStyles: _buildQuillStyles(isDark),
                ),
              ),

              const SizedBox(height: 200),
            ],
          ),
        ),
      ),
    );
  }

  DefaultStyles _buildQuillStyles(bool isDark) {
    final baseTextColor = isDark ? Colors.white.withAlpha(230) : Colors.black87;
    final mutedColor = isDark ? Colors.white54 : Colors.black54;

    return DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        GoogleFonts.inter(
          fontSize: 17,
          color: baseTextColor,
          height: 1.8,
          letterSpacing: 0.2,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(10, 10),
        const VerticalSpacing(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
        GoogleFonts.outfit(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: baseTextColor,
          height: 1.5,
          letterSpacing: -0.5,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(24, 12),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: baseTextColor,
          height: 1.5,
          letterSpacing: -0.3,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(20, 10),
        const VerticalSpacing(0, 0),
        null,
      ),
      h3: DefaultTextBlockStyle(
        GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: baseTextColor,
          height: 1.5,
          letterSpacing: -0.2,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(16, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      bold: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: baseTextColor,
      ),
      italic: GoogleFonts.inter(
        fontStyle: FontStyle.italic,
        color: baseTextColor,
      ),
      underline: GoogleFonts.inter(
        decoration: TextDecoration.underline,
        color: baseTextColor,
      ),
      lists: DefaultListBlockStyle(
        GoogleFonts.inter(
          fontSize: 17,
          color: baseTextColor,
          height: 1.7,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        null,
        null,
      ),
      quote: DefaultTextBlockStyle(
        GoogleFonts.inter(
          fontSize: 17,
          fontStyle: FontStyle.italic,
          color: mutedColor,
          height: 1.6,
        ),
        const HorizontalSpacing(16, 0),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppTheme.primaryColor.withAlpha(100),
              width: 3,
            ),
          ),
        ),
      ),
      placeHolder: DefaultTextBlockStyle(
        GoogleFonts.inter(
          fontSize: 17,
          color: isDark ? Colors.white24 : Colors.black26,
          height: 1.7,
        ),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }

  Widget _buildFormattingToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToolbarButton(
              icon: Icons.format_size,
              label: 'H1',
              isActive: _isHeaderActive(1),
              onTap: () => _toggleHeader(1),
              isDark: isDark,
            ),
            _buildToolbarButton(
              icon: Icons.format_size,
              label: 'H2',
              isActive: _isHeaderActive(2),
              onTap: () => _toggleHeader(2),
              isDark: isDark,
              isSmall: true,
            ),
            _buildToolbarButton(
              icon: Icons.format_bold,
              isActive: _isStyleActive(Attribute.bold),
              onTap: () => _toggleStyle(Attribute.bold),
              isDark: isDark,
            ),
            _buildToolbarButton(
              icon: Icons.format_italic,
              isActive: _isStyleActive(Attribute.italic),
              onTap: () => _toggleStyle(Attribute.italic),
              isDark: isDark,
            ),
            _buildToolbarButton(
              icon: Icons.format_underline,
              isActive: _isStyleActive(Attribute.underline),
              onTap: () => _toggleStyle(Attribute.underline),
              isDark: isDark,
            ),
            _buildToolbarButton(
              icon: Icons.format_list_bulleted,
              isActive: _isListActive(),
              onTap: _toggleBulletList,
              isDark: isDark,
            ),
            _buildToolbarButton(
              icon: Icons.format_quote,
              isActive: _isQuoteActive(),
              onTap: _toggleQuote,
              isDark: isDark,
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 200.ms);
  }

  Widget _buildToolbarButton({
    required IconData icon,
    String? label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: label != null
              ? Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: isSmall ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                )
              : Icon(
                  icon,
                  size: 22,
                  color: isActive
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
        ),
      ),
    );
  }

  // Toolbar helper methods
  bool _isStyleActive(Attribute attribute) {
    return _quillController.getSelectionStyle().containsKey(attribute.key);
  }

  bool _isHeaderActive(int level) {
    final style = _quillController.getSelectionStyle();
    final header = style.attributes[Attribute.header.key];
    return header?.value == level;
  }

  bool _isListActive() {
    final style = _quillController.getSelectionStyle();
    return style.containsKey(Attribute.list.key);
  }

  bool _isQuoteActive() {
    final style = _quillController.getSelectionStyle();
    return style.containsKey(Attribute.blockQuote.key);
  }

  void _toggleStyle(Attribute attribute) {
    if (_isStyleActive(attribute)) {
      _quillController.formatSelection(Attribute.clone(attribute, null));
    } else {
      _quillController.formatSelection(attribute);
    }
  }

  void _toggleHeader(int level) {
    if (_isHeaderActive(level)) {
      _quillController.formatSelection(Attribute.clone(Attribute.header, null));
    } else {
      _quillController.formatSelection(HeaderAttribute(level: level));
    }
  }

  void _toggleBulletList() {
    if (_isListActive()) {
      _quillController.formatSelection(Attribute.clone(Attribute.list, null));
    } else {
      _quillController.formatSelection(Attribute.ul);
    }
  }

  void _toggleQuote() {
    if (_isQuoteActive()) {
      _quillController.formatSelection(Attribute.clone(Attribute.blockQuote, null));
    } else {
      _quillController.formatSelection(Attribute.blockQuote);
    }
  }

  // Dialog methods
  void _showSpeakerDialog(bool isDark) {
    final controller = TextEditingController(text: _preacher);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildInputSheet(
        title: 'Speaker',
        hint: 'Pastor name',
        controller: controller,
        icon: LucideIcons.mic2,
        isDark: isDark,
        onSave: () {
          setState(() {
            _preacher = controller.text.trim();
            _hasUnsavedChanges = true;
          });
          Navigator.pop(ctx);
          _scheduleAutoSave();
        },
      ),
    );
  }

  void _showVerseDialog(bool isDark) {
    final controller = TextEditingController(text: _verse);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildInputSheet(
        title: 'Bible Reference',
        hint: 'e.g., John 3:16',
        controller: controller,
        icon: LucideIcons.bookOpen,
        isDark: isDark,
        onSave: () {
          setState(() {
            _verse = controller.text.trim();
            _hasUnsavedChanges = true;
          });
          Navigator.pop(ctx);
          _scheduleAutoSave();
        },
      ),
    );
  }

  Widget _buildInputSheet({
    required String title,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    required VoidCallback onSave,
  }) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSubmitted: (_) => onSave(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePicker(bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _hasUnsavedChanges = true;
      });
      _scheduleAutoSave();
    }
  }

  void _showSeriesSelector(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocBuilder<SermonCubit, SermonState>(
        builder: (context, state) {
          final series = state is SermonLoaded
              ? state.folders
                  .where((f) => f.id != null && f.id != 'uncategorized' && !f.isAllSermons)
                  .toList()
              : <SermonFolder>[];

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.folder, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Select Series',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                // No Series option
                ListTile(
                  leading: Icon(
                    LucideIcons.fileText,
                    color: _selectedSeriesId == null
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                  title: Text(
                    'No Series',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  trailing: _selectedSeriesId == null
                      ? const Icon(LucideIcons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedSeriesId = null;
                      _selectedSeriesName = null;
                      _hasUnsavedChanges = true;
                    });
                    Navigator.pop(ctx);
                    _scheduleAutoSave();
                  },
                ),
                const Divider(height: 1),
                ...series.map((folder) => ListTile(
                  leading: Icon(
                    LucideIcons.folder,
                    color: _selectedSeriesId == folder.id
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                  title: Text(
                    folder.name,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: _selectedSeriesId == folder.id
                      ? const Icon(LucideIcons.check, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedSeriesId = folder.id;
                      _selectedSeriesName = folder.name;
                      _hasUnsavedChanges = true;
                    });
                    Navigator.pop(ctx);
                    _scheduleAutoSave();
                  },
                )),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMoreOptions(bool isDark) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Community Toggle (Publish to Community)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.primaryColor.withAlpha(20)
                      : AppTheme.primaryColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withAlpha(30),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.globe,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Publish to Community',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Share with other believers',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (value) {
                        setModalState(() => _isPublic = value);
                        setState(() => _isPublic = value);
                        _hasUnsavedChanges = true;
                        _scheduleAutoSave();

                        // Show "Coming Soon" toast
                        if (value) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Community sharing coming soon!',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.primaryColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      activeTrackColor: AppTheme.primaryColor.withAlpha(100),
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.primaryColor;
                        }
                        return null;
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_existingNote != null) ...[
                ListTile(
                  leading: Icon(
                    _existingNote!.isPinned ? LucideIcons.pinOff : LucideIcons.pin,
                    color: AppTheme.goldenPromise,
                  ),
                  title: Text(_existingNote!.isPinned ? 'Unpin Note' : 'Pin Note'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<SermonCubit>().togglePin(_existingNote!.id);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.share2, color: AppTheme.primaryColor),
                  title: const Text('Share'),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showShareSheet(isDark);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete();
                  },
                ),
              ],
              ListTile(
                leading: Icon(
                  LucideIcons.info,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                title: const Text('Word Count'),
                trailing: Text(
                  '${_quillController.document.toPlainText().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Advanced Sharing System
  void _showShareSheet(bool isDark) {
    HapticFeedback.selectionClick();

    final title = _titleController.text.trim();
    final plainText = _quillController.document.toPlainText().trim();
    final verse = _verse.isNotEmpty ? _verse : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                const Icon(LucideIcons.share2, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Share Sermon Notes',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Share Options Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Share as Text
                _buildShareOption(
                  icon: LucideIcons.messageSquare,
                  label: 'Text',
                  color: AppTheme.primaryColor,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareAsText(title, plainText, verse);
                  },
                ),

                // Share as PDF
                _buildShareOption(
                  icon: LucideIcons.fileText,
                  label: 'PDF',
                  color: Colors.red.shade400,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareAsPdf(title, plainText, verse);
                  },
                ),

                // Share via Email
                _buildShareOption(
                  icon: LucideIcons.mail,
                  label: 'Email',
                  color: Colors.blue.shade400,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareViaEmail(title, plainText, verse);
                  },
                ),

                // Share as Image (Coming Soon)
                _buildShareOption(
                  icon: LucideIcons.image,
                  label: 'Image',
                  color: Colors.orange.shade400,
                  isDark: isDark,
                  isComingSoon: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Quote card sharing coming soon!',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        backgroundColor: AppTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              if (isComingSoon)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.goldenPromise,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Soon',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Share as plain text (for WhatsApp, SMS, etc.)
  void _shareAsText(String title, String content, String? verse) {
    final buffer = StringBuffer();
    buffer.writeln('✝️ $title');
    buffer.writeln();
    if (_preacher.isNotEmpty) {
      buffer.writeln('🎤 Speaker: $_preacher');
    }
    if (verse != null && verse.isNotEmpty) {
      buffer.writeln('📖 Scripture: $verse');
    }
    buffer.writeln('📅 ${_formatDateShort(_selectedDate)}');
    buffer.writeln();
    buffer.writeln(content);
    buffer.writeln();
    buffer.writeln('— Shared from Kneel App');

    Share.share(buffer.toString(), subject: title);
  }

  /// Share as PDF (shows coming soon for now)
  void _shareAsPdf(String title, String content, String? verse) {
    // For now, share as formatted text since PDF generation requires additional setup
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.info, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'PDF export coming in next update!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Share Text',
          textColor: Colors.white,
          onPressed: () => _shareAsText(title, content, verse),
        ),
      ),
    );
  }

  /// Share via Email with HTML formatting
  void _shareViaEmail(String title, String content, String? verse) {
    final buffer = StringBuffer();
    buffer.writeln('$title\n');
    if (_preacher.isNotEmpty) {
      buffer.writeln('Speaker: $_preacher');
    }
    if (verse != null && verse.isNotEmpty) {
      buffer.writeln('Scripture: $verse');
    }
    buffer.writeln('Date: ${_formatDateShort(_selectedDate)}\n');
    buffer.writeln('---\n');
    buffer.writeln(content);
    buffer.writeln('\n---');
    buffer.writeln('Shared from Kneel - Your Personal Prayer Companion');

    Share.share(
      buffer.toString(),
      subject: '📖 Sermon Notes: $title',
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('This cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _existingNote != null && mounted) {
      await context.read<SermonCubit>().deleteSermon(_existingNote!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  String _formatDateShort(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Sanitizes Quill Delta to remove problematic control characters.
  /// Keeps newlines (\n) and tabs (\t) but removes other control chars.
  List<dynamic> _sanitizeDelta(List<dynamic> delta) {
    return delta.map((op) {
      if (op is Map<String, dynamic>) {
        final sanitized = Map<String, dynamic>.from(op);
        if (sanitized['insert'] is String) {
          // Remove control characters except \n (newline) and \t (tab)
          sanitized['insert'] = (sanitized['insert'] as String)
              .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
        }
        return sanitized;
      }
      return op;
    }).toList();
  }
}
