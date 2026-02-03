import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quick_church/core/theme/app_theme.dart';

/// Premium shimmer loading effects for the Sermon Vault.
/// Replaces standard CircularProgressIndicator with beautiful skeleton loaders.
class VaultShimmer extends StatelessWidget {
  const VaultShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
      highlightColor: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            _buildHeaderShimmer(),
            const SizedBox(height: 24),

            // Search bar shimmer
            _buildSearchShimmer(),
            const SizedBox(height: 24),

            // Section title shimmer
            _buildSectionTitleShimmer(),
            const SizedBox(height: 16),

            // Grid shimmer
            _buildGridShimmer(),
            const SizedBox(height: 24),

            // Recent section shimmer
            _buildSectionTitleShimmer(),
            const SizedBox(height: 16),
            _buildListShimmer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderShimmer() {
    return Row(
      children: [
        // Logo placeholder
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 12),
        // Title placeholder
        Container(
          width: 150,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const Spacer(),
        // Sync indicator placeholder
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchShimmer() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildSectionTitleShimmer() {
    return Container(
      width: 100,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildGridShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.9,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildListShimmer() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Shimmer for individual series cards in grid.
class SeriesCardShimmer extends StatelessWidget {
  final bool isDark;
  final int count;

  const SeriesCardShimmer({
    super.key,
    required this.isDark,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
      highlightColor: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.9,
        ),
        itemCount: count,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

/// Shimmer for sermon note list items.
class SermonNoteShimmer extends StatelessWidget {
  final bool isDark;
  final int count;

  const SermonNoteShimmer({
    super.key,
    required this.isDark,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
      highlightColor: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: count,
        itemBuilder: (context, index) => _buildTimelineShimmerItem(),
      ),
    );
  }

  Widget _buildTimelineShimmerItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 60,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Card
          Expanded(
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sync status indicator widget.
class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _getBorderColor(isDark),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(isDark),
            const SizedBox(width: 6),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getTextColor(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    switch (status) {
      case SyncStatus.synced:
        return Icon(
          Icons.cloud_done_rounded,
          size: 16,
          color: AppTheme.secondaryColor,
        );
      case SyncStatus.syncing:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white70 : AppTheme.primaryColor,
            ),
          ),
        );
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off_rounded,
          size: 16,
          color: isDark ? Colors.white54 : Colors.black45,
        );
      case SyncStatus.pending:
        return Icon(
          Icons.cloud_upload_rounded,
          size: 16,
          color: Colors.orange,
        );
      case SyncStatus.error:
        return const Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: Colors.red,
        );
    }
  }

  String _getStatusText() {
    switch (status) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.error:
        return 'Sync Error';
    }
  }

  Color _getBackgroundColor(bool isDark) {
    switch (status) {
      case SyncStatus.synced:
        return AppTheme.secondaryColor.withAlpha(isDark ? 30 : 20);
      case SyncStatus.syncing:
        return isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100;
      case SyncStatus.offline:
        return isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100;
      case SyncStatus.pending:
        return Colors.orange.withAlpha(isDark ? 30 : 20);
      case SyncStatus.error:
        return Colors.red.withAlpha(isDark ? 30 : 20);
    }
  }

  Color _getBorderColor(bool isDark) {
    switch (status) {
      case SyncStatus.synced:
        return AppTheme.secondaryColor.withAlpha(50);
      case SyncStatus.syncing:
        return isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200;
      case SyncStatus.offline:
        return isDark ? Colors.white.withAlpha(20) : Colors.grey.shade200;
      case SyncStatus.pending:
        return Colors.orange.withAlpha(50);
      case SyncStatus.error:
        return Colors.red.withAlpha(50);
    }
  }

  Color _getTextColor(bool isDark) {
    switch (status) {
      case SyncStatus.synced:
        return AppTheme.secondaryColor;
      case SyncStatus.syncing:
        return isDark ? Colors.white70 : Colors.black54;
      case SyncStatus.offline:
        return isDark ? Colors.white54 : Colors.black45;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.error:
        return Colors.red;
    }
  }
}

/// Sync status enum for the indicator.
enum SyncStatus {
  synced,
  syncing,
  offline,
  pending,
  error,
}
