import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/domain/entities/prayer.dart';

/// Full-screen testimony detail view with Hero animation.
/// Features image gallery, share functionality, and community toggle.
class TestimonyDetailView extends StatefulWidget {
  final Prayer prayer;
  final Function(bool isPublic)? onPublicToggle;
  final Function(String? imageUrl)? onImageChanged;
  final Function(String testimony)? onTestimonyChanged;

  const TestimonyDetailView({
    super.key,
    required this.prayer,
    this.onPublicToggle,
    this.onImageChanged,
    this.onTestimonyChanged,
  });

  @override
  State<TestimonyDetailView> createState() => _TestimonyDetailViewState();
}

class _TestimonyDetailViewState extends State<TestimonyDetailView> {
  // ignore: unused_field - reserved for future image capture implementation
  final GlobalKey _shareCardKey = GlobalKey();
  late bool _isPublic;
  bool _isSharing = false;
  bool _isUploadingImage = false;
  String? _localImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isPublic = widget.prayer.isPublicTestimony;
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show picker options
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Testimony Photo',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a meaningful image to accompany your testimony',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceOption(
                      icon: LucideIcons.camera,
                      label: 'Camera',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImageSourceOption(
                      icon: LucideIcons.image,
                      label: 'Gallery',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      setState(() => _isUploadingImage = true);

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      // Crop the image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Testimony Photo',
            toolbarColor: AppTheme.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Testimony Photo',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() {
          _localImagePath = croppedFile.path;
        });

        // Notify parent to handle upload (e.g., to Supabase)
        widget.onImageChanged?.call(croppedFile.path);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Photo added to testimony',
              style: GoogleFonts.inter(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add photo',
              style: GoogleFonts.inter(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _removeImage() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Photo?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will remove the photo from your testimony.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _localImagePath = null);
              widget.onImageChanged?.call(null);
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasNetworkImage = widget.prayer.testimonyImageUrl != null &&
        widget.prayer.testimonyImageUrl!.isNotEmpty;
    final hasLocalImage = _localImagePath != null;
    final hasImage = hasNetworkImage || hasLocalImage;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: hasImage ? 300 : 150,
            pinned: true,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.arrowLeft, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.share2, color: Colors.white),
                ),
                onPressed: _shareTestimony,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'testimony_${widget.prayer.id}',
                child: hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          // Show local image if available, otherwise network image
                          if (hasLocalImage)
                            Image.file(
                              File(_localImagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderBackground(isDark),
                            )
                          else if (hasNetworkImage)
                            Image.network(
                              widget.prayer.testimonyImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderBackground(isDark),
                            ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withAlpha(100),
                                  Colors.transparent,
                                  Colors.black.withAlpha(150),
                                ],
                                stops: const [0.0, 0.4, 1.0],
                              ),
                            ),
                          ),
                          // Loading indicator when uploading
                          if (_isUploadingImage)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          // Edit photo button
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: GestureDetector(
                              onTap: hasImage ? _removeImage : _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  hasImage ? LucideIcons.trash2 : LucideIcons.camera,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildPlaceholderWithAddButton(isDark),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Victory badge and date
                  Row(
                    children: [
                      _buildVictoryBadge(),
                      const Spacer(),
                      if (widget.prayer.answeredAt != null)
                        Text(
                          _formatFullDate(widget.prayer.answeredAt!),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Prayer title
                  Text(
                    widget.prayer.title,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Original prayer description
                  Text(
                    widget.prayer.description,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.6,
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.goldenPromise.withAlpha(60),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Testimony section
                  Row(
                    children: [
                      Icon(
                        LucideIcons.quote,
                        size: 20,
                        color: AppTheme.goldenPromise,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Testimony',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.goldenPromise,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (widget.prayer.testimony != null &&
                      widget.prayer.testimony!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.goldenPromise.withAlpha(15)
                            : AppTheme.goldenPromise.withAlpha(10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.goldenPromise.withAlpha(30),
                        ),
                      ),
                      child: Text(
                        widget.prayer.testimony!,
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.8,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    _buildAddTestimonyPrompt(isDark),

                  const SizedBox(height: 24),

                  // Stats row
                  _buildStatsRow(isDark),

                  const SizedBox(height: 24),

                  // Community toggle
                  _buildCommunityToggle(isDark),

                  const SizedBox(height: 32),

                  // Share button
                  _buildShareButton(isDark),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withAlpha(100),
            AppTheme.goldenPromise.withAlpha(80),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.trophy,
          size: 64,
          color: AppTheme.goldenPromise.withAlpha(150),
        ),
      ),
    );
  }

  Widget _buildPlaceholderWithAddButton(bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withAlpha(100),
              AppTheme.goldenPromise.withAlpha(80),
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.trophy,
                    size: 64,
                    color: AppTheme.goldenPromise.withAlpha(150),
                  ),
                ],
              ),
            ),
            // Add photo button
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.camera,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Photo',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Loading overlay
            if (_isUploadingImage)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVictoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.goldenPromise.withAlpha(40),
            AppTheme.goldenPromise.withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.goldenPromise.withAlpha(60),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.trophy,
            size: 16,
            color: AppTheme.goldenPromise,
          ),
          const SizedBox(width: 8),
          Text(
            'Answered Prayer',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.goldenPromise,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTestimonyPrompt(bool isDark) {
    return GestureDetector(
      onTap: () {
        // TODO: Open testimony editor
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(8) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.pencil,
              size: 32,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'Add your testimony',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share how God answered this prayer',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final daysToAnswer = widget.prayer.daysToAnswer ?? 0;
    final prayerCount = widget.prayer.prayerCount;
    final weeksOfPrayer = (daysToAnswer / 7).ceil();

    return Column(
      children: [
        // First row: Time to answer + Times prayed
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: LucideIcons.clock,
                value: daysToAnswer == 0 ? 'Same day' : '$daysToAnswer days',
                label: 'Time to answer',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatItem(
                icon: LucideIcons.flame,
                value: '$prayerCount×',
                label: 'Times prayed',
                isDark: isDark,
                isHighlighted: prayerCount >= 10, // Gold highlight for persistent prayers
              ),
            ),
          ],
        ),
        // Persistence summary for significant prayer journeys
        if (daysToAnswer > 7 && prayerCount > 5) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldenPromise.withAlpha(isDark ? 30 : 20),
                  AppTheme.goldenPromise.withAlpha(isDark ? 15 : 10),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.goldenPromise.withAlpha(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.trophy,
                  size: 18,
                  color: AppTheme.goldenPromise,
                ),
                const SizedBox(width: 10),
                Text(
                  'Prayed $prayerCount times over $weeksOfPrayer ${weeksOfPrayer == 1 ? 'week' : 'weeks'}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.goldenPromise,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppTheme.goldenPromise.withAlpha(isDark ? 20 : 15)
            : (isDark ? Colors.white.withAlpha(8) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: AppTheme.goldenPromise.withAlpha(40))
            : null,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: isHighlighted ? AppTheme.goldenPromise : AppTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isHighlighted
                  ? AppTheme.goldenPromise
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(8)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isPublic
              ? AppTheme.primaryColor.withAlpha(40)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isPublic
                  ? AppTheme.primaryColor.withAlpha(30)
                  : (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isPublic ? LucideIcons.globe : LucideIcons.lock,
              size: 22,
              color: _isPublic
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Make Testimony Public?',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _isPublic
                      ? 'Your testimony inspires the community'
                      : 'Only visible to you',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _isPublic = value);
              widget.onPublicToggle?.call(value);
            },
            activeTrackColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(bool isDark) {
    return FilledButton.icon(
      onPressed: _isSharing ? null : _shareTestimony,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.goldenPromise,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        minimumSize: const Size(double.infinity, 56),
      ),
      icon: _isSharing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black54,
              ),
            )
          : const Icon(LucideIcons.share2, size: 20),
      label: Text(
        _isSharing ? 'Creating image...' : 'Share Testimony',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _shareTestimony() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      // Create shareable image
      final imageBytes = await _createShareableImage();

      if (imageBytes != null) {
        // Save to temp file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/testimony_${widget.prayer.id}.png');
        await file.writeAsBytes(imageBytes);

        // Share
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'My testimony: ${widget.prayer.title}\n\n${widget.prayer.testimony ?? ""}\n\n#Kneel #PrayerAnswered',
        );
      } else {
        // Fallback to text sharing
        await Share.share(
          'My testimony: ${widget.prayer.title}\n\n'
          '${widget.prayer.testimony ?? widget.prayer.description}\n\n'
          '#Kneel #PrayerAnswered',
        );
      }
    } catch (e) {
      // Fallback to text sharing
      await Share.share(
        'My testimony: ${widget.prayer.title}\n\n'
        '${widget.prayer.testimony ?? widget.prayer.description}\n\n'
        '#Kneel #PrayerAnswered',
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<Uint8List?> _createShareableImage() async {
    // TODO: Implement proper image capture with ScreenshotController
    // For now, return null and use text sharing as fallback
    // The _shareCardKey and _ShareTestimonyCard are ready for future implementation
    return null;
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Image source option button for the picker sheet.
class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Branded card for sharing testimonies as images.
// ignore: unused_element - reserved for future image generation implementation
class _ShareTestimonyCard extends StatelessWidget {
  final Prayer prayer;

  const _ShareTestimonyCard({required this.prayer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withAlpha(200),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.flame,
                size: 28,
                color: AppTheme.goldenPromise,
              ),
              const SizedBox(width: 8),
              Text(
                'KNEEL',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Victory badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.goldenPromise.withAlpha(40),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.trophy,
                  size: 16,
                  color: AppTheme.goldenPromise,
                ),
                const SizedBox(width: 8),
                Text(
                  'Prayer Answered',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.goldenPromise,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Prayer title
          Text(
            prayer.title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Testimony
          if (prayer.testimony != null && prayer.testimony!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '"${prayer.testimony}"',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),

          // Footer
          Text(
            'kneel.app',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white54,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
