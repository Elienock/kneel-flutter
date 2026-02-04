import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/pulpit/domain/entities/pulpit_prayer_group.dart';
import 'package:quick_church/features/pulpit/presentation/bloc/pulpit_cubit.dart';
import 'package:quick_church/features/pulpit/presentation/bloc/pulpit_state.dart';
import 'package:quick_church/features/pulpit/presentation/pages/pulpit_group_editor_page.dart';
import 'package:quick_church/features/pulpit/presentation/pages/pulpit_session_page.dart';

/// Main page listing all pulpit prayer groups.
class PulpitGroupsPage extends StatefulWidget {
  const PulpitGroupsPage({super.key});

  @override
  State<PulpitGroupsPage> createState() => _PulpitGroupsPageState();
}

class _PulpitGroupsPageState extends State<PulpitGroupsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PulpitCubit>().loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          'Pulpit Mode',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'What is Pulpit Mode?',
          ),
        ],
      ),
      body: BlocBuilder<PulpitCubit, PulpitState>(
        builder: (context, state) {
          if (state.status == PulpitStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.groups.isEmpty) {
            return _buildEmptyState(context, isDark);
          }

          return RefreshIndicator(
            onRefresh: () => context.read<PulpitCubit>().loadGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.groups.length,
              itemBuilder: (context, index) {
                return _PulpitGroupCard(
                  group: state.groups[index],
                  onTap: () => _openGroup(context, state.groups[index]),
                  onStart: () => _startSession(context, state.groups[index]),
                  onDelete: () => _confirmDelete(context, state.groups[index]),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewGroup(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Prayer Group'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.mic2,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pulpit Mode',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lead your congregation through structured prayer points from the pulpit.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _createNewGroup(context),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Create Prayer Group'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.mic2, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text('Pulpit Mode', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(LucideIcons.users, 'Lead group prayer sessions'),
            _buildHelpItem(LucideIcons.listOrdered, 'Organize prayer points in order'),
            _buildHelpItem(LucideIcons.bookOpen, 'Include scripture references'),
            _buildHelpItem(LucideIcons.timer, 'Auto-advance or manual timing'),
            _buildHelpItem(LucideIcons.save, 'Save groups for reuse'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _createNewGroup(BuildContext context) async {
    HapticFeedback.mediumImpact();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: context.read<PulpitCubit>(),
          child: const PulpitGroupEditorPage(),
        ),
      ),
    );
  }

  Future<void> _openGroup(BuildContext context, PulpitPrayerGroup group) async {
    HapticFeedback.selectionClick();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: context.read<PulpitCubit>(),
          child: PulpitGroupEditorPage(groupId: group.id),
        ),
      ),
    );
  }

  Future<void> _startSession(BuildContext context, PulpitPrayerGroup group) async {
    HapticFeedback.mediumImpact();

    // Load full group with points
    final cubit = context.read<PulpitCubit>();
    final fullGroup = await cubit.loadGroupWithPoints(group.id);

    if (fullGroup == null || fullGroup.points.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add prayer points before starting a session'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => BlocProvider.value(
            value: cubit,
            child: PulpitSessionPage(group: fullGroup),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, PulpitPrayerGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Prayer Group?'),
        content: Text(
          'Are you sure you want to delete "${group.title}"? This cannot be undone.',
        ),
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
      context.read<PulpitCubit>().deleteGroup(group.id);
    }
  }
}

/// Card widget for a pulpit prayer group.
class _PulpitGroupCard extends StatelessWidget {
  final PulpitPrayerGroup group;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  const _PulpitGroupCard({
    required this.group,
    required this.onTap,
    required this.onStart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.mic2,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (group.description != null && group.description!.isNotEmpty)
                          Text(
                            group.description!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.moreVertical),
                    onSelected: (value) {
                      if (value == 'edit') onTap();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.pencil, size: 18),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2, size: 18, color: AppTheme.urgentColor),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: AppTheme.urgentColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    LucideIcons.timer,
                    group.autoAdvance ? group.durationLabel : 'Manual',
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  if (group.timesUsed > 0)
                    _buildInfoChip(
                      LucideIcons.repeat,
                      'Used ${group.timesUsed}x',
                      isDark,
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: const Text('Start'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
