import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/sermon/domain/entities/sermon_note.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_cubit.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_state.dart';

/// Collapsible metadata header for the sermon editor.
class MetadataHeader extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final TextEditingController preacherController;
  final TextEditingController verseController;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final String? selectedSeriesId;
  final String? selectedSeriesName;
  final bool isNewSeries;
  final TextEditingController newSeriesController;
  final void Function(String? id, String? name) onSeriesChanged;
  final VoidCallback onNewSeries;
  final bool isDark;

  const MetadataHeader({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.preacherController,
    required this.verseController,
    required this.selectedDate,
    required this.onDateChanged,
    required this.selectedSeriesId,
    required this.selectedSeriesName,
    required this.isNewSeries,
    required this.newSeriesController,
    required this.onSeriesChanged,
    required this.onNewSeries,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toggle Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.fileText,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sermon Details',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      LucideIcons.chevronDown,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(context),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Preacher Field
          _buildMetadataField(
            context,
            icon: LucideIcons.user,
            label: 'Preacher',
            child: TextField(
              controller: preacherController,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Pastor name',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Main Verse Field
          _buildMetadataField(
            context,
            icon: LucideIcons.bookOpen,
            label: 'Main Verse',
            child: TextField(
              controller: verseController,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., John 3:16',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date Picker
          _buildMetadataField(
            context,
            icon: LucideIcons.calendar,
            label: 'Date',
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Text(
                _formatDate(selectedDate),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Series Dropdown
          _buildSeriesField(context),
        ],
      ),
    );
  }

  Widget _buildMetadataField(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildSeriesField(BuildContext context) {
    return BlocBuilder<SermonCubit, SermonState>(
      builder: (context, state) {
        // Get series folders (exclude All Sermons and Uncategorized)
        final seriesFolders = state is SermonLoaded
            ? state.folders
                .where((f) => f.id != null && f.id != 'uncategorized' && !f.isAllSermons)
                .toList()
            : <SermonFolder>[];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.folder,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: Text(
                'Series',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
            Expanded(
              child: isNewSeries
                  ? _buildNewSeriesInput()
                  : _buildSeriesDropdown(context, seriesFolders),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeriesDropdown(BuildContext context, List<SermonFolder> seriesFolders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedSeriesId,
              isExpanded: true,
              hint: Text(
                'Select series',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
              icon: Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    'No series',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                ...seriesFolders.map((folder) => DropdownMenuItem<String?>(
                      value: folder.id,
                      child: Text(
                        folder.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    )),
              ],
              onChanged: (id) {
                if (id == null) {
                  onSeriesChanged(null, null);
                } else {
                  String? folderName;
                  try {
                    final folder = seriesFolders.firstWhere((f) => f.id == id);
                    folderName = folder.name;
                  } catch (_) {
                    // Folder not found
                  }
                  onSeriesChanged(id, folderName);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onNewSeries,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.plus,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Create new series',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewSeriesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          child: TextField(
            controller: newSeriesController,
            autofocus: true,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Enter series name',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onSeriesChanged(null, null),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.x,
                size: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              const SizedBox(width: 4),
              Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
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
      onDateChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
