import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:quick_church/core/l10n/app_strings.dart';
import 'package:quick_church/core/services/places_api_service.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';

/// 3-step animated onboarding flow.
/// Step 1: Photo upload with Google pre-fill
/// Step 2: Full Name and Bio input
/// Step 3: Location search using Google Places API (New)
class OnboardingPage extends StatefulWidget {
  final String? initialPhotoUrl;
  final String? initialDisplayName;

  const OnboardingPage({
    super.key,
    this.initialPhotoUrl,
    this.initialDisplayName,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _placesService = PlacesApiService();

  int _currentStep = 0;
  String? _photoUrl;
  String? _selectedLocationCity;
  String? _selectedPlaceId;
  bool _isCompleting = false;
  bool _isSearching = false;
  bool _isUploadingPhoto = false;
  List<PlacePrediction> _predictions = [];
  ({double lat, double lng})? _locationBias;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.initialPhotoUrl;
    _nameController.text = widget.initialDisplayName ?? '';
    _bioController.text = AppStrings.defaultBio;
    _initLocationBias();
  }

  /// Initializes location bias for improved city search relevance.
  /// Only requests 'whileInUse' permission to comply with Play Store/App Store guidelines.
  Future<void> _initLocationBias() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      // Check current permission status
      var permission = await Geolocator.checkPermission();

      // Only request permission if denied (not deniedForever)
      if (permission == LocationPermission.denied) {
        // This requests 'whileInUse' permission by default
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      // Don't proceed if permission is denied forever
      if (permission == LocationPermission.deniedForever) return;

      // Only proceed with whileInUse or always permission
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Use low accuracy to minimize battery usage and privacy concerns
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
        );
        if (mounted) {
          setState(() {
            _locationBias = (lat: position.latitude, lng: position.longitude);
          });
        }
      }
    } catch (e) {
      // Location not available, continue without bias
      // This is not critical - the search will work without location bias
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _placesService.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return true; // Photo is optional
      case 1:
        return _nameController.text.trim().isNotEmpty;
      case 2:
        return _selectedLocationCity != null && _selectedPlaceId != null;
      default:
        return false;
    }
  }

  Future<void> _pickPhoto() async {
    // Capture cubit before async gap
    final profileCubit = context.read<ProfileCubit>();

    // Show source selection dialog
    final source = await _showPhotoSourceDialog();
    if (source == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final newPhotoUrl = await profileCubit.uploadProfilePhoto(
        source: source,
      );

      if (newPhotoUrl != null && mounted) {
        setState(() {
          _photoUrl = newPhotoUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: ${e.toString().split(':').last}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<ImageSource?> _showPhotoSourceDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Choose Photo',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.camera, color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    'Take Photo',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Use your camera',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.image, color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Select from your photos',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _searchPlaces(String query) async {
    // Clear selection when user starts typing again
    if (_selectedLocationCity != null) {
      setState(() {
        _selectedLocationCity = null;
        _selectedPlaceId = null;
      });
    }

    if (query.trim().isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    // Only search if query has at least 2 characters
    if (query.trim().length < 2) {
      return;
    }

    setState(() => _isSearching = true);

    try {
      debugPrint('[Onboarding] Searching for: "$query"');
      final results = await _placesService.searchPlaces(
        query: query,
        locationBias: _locationBias,
      );
      debugPrint('[Onboarding] Got ${results.length} results');

      if (mounted) {
        setState(() {
          _predictions = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('[Onboarding] Search error: $e');
      if (mounted) {
        setState(() {
          _predictions = [];
          _isSearching = false;
        });
        // Show error snackbar for debugging
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString().split('\n').first}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectPlace(PlacePrediction place) {
    setState(() {
      _selectedLocationCity = place.formattedAddress ?? place.displayName;
      _selectedPlaceId = place.placeId;
      _locationController.text = place.displayName;
      _predictions = [];
    });
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;

    setState(() => _isCompleting = true);

    try {
      // Photo is already uploaded in step 1 via ProfileCubit.uploadProfilePhoto
      // _photoUrl contains the Supabase Storage URL with cache-busting timestamp
      await context.read<ProfileCubit>().completeOnboarding(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        locationCity: _selectedLocationCity!,
        googlePlaceId: _selectedPlaceId!,
        photoUrl: _photoUrl, // Already uploaded URL or initial Google photo URL
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorPrefix} $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          // Onboarding complete - the main.dart will handle navigation
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      // PopScope prevents back button from popping to login while authenticated
      child: PopScope(
        canPop: false,
        child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Header with progress
              _buildHeader(isDark),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPhotoStep(isDark),
                    _buildBioStep(isDark),
                    _buildLocationStep(isDark),
                  ],
                ),
              ),

              // Bottom navigation
              _buildBottomNav(isDark),
            ],
          ),
        ),
      ),
    ),  // PopScope
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppStrings.appName,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Progress indicator
          FadeIn(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
            child: Row(
              children: List.generate(3, (index) {
                final isActive = index <= _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primaryColor
                          : (isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: isCurrent
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Step label
          FadeIn(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 300),
            child: Text(
              AppStrings.formatStep(_currentStep + 1, 3),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep(bool isDark) {
    final profileState = context.watch<ProfileCubit>().state;
    final isGoogleUser = profileState is ProfileNeedsOnboarding &&
        profileState.profile.isGoogleUser;
    final hasPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;

    return FadeInRight(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            Text(
              AppStrings.addYourPhoto,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.photoSubtitle,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Avatar with upload
            GestureDetector(
              onTap: _isUploadingPhoto ? null : _pickPhoto,
              child: Stack(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha:0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha:0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _isUploadingPhoto
                        ? _buildUploadingOverlay(isDark)
                        : _buildAvatarContent(),
                  ),
                  if (!_isUploadingPhoto)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppTheme.darkBackground : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic text based on state
            if (_isUploadingPhoto)
              Text(
                'Uploading...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              )
            else if (isGoogleUser && hasPhoto)
              GestureDetector(
                onTap: _pickPhoto,
                child: Text(
                  'Change Photo',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Text(
                AppStrings.tapToUpload,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingOverlay(bool isDark) {
    return ClipOval(
      child: Stack(
        children: [
          // Show current photo or placeholder behind shimmer
          _buildAvatarContent(),
          // Shimmer overlay
          Shimmer.fromColors(
            baseColor: Colors.transparent,
            highlightColor: Colors.white.withValues(alpha:0.4),
            child: Container(
              width: 150,
              height: 150,
              color: Colors.black.withValues(alpha:0.3),
            ),
          ),
          // Loading indicator
          Container(
            width: 150,
            height: 150,
            color: Colors.black.withValues(alpha:0.4),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: _photoUrl!,
          fit: BoxFit.cover,
          width: 150,
          height: 150,
          placeholder: (context, url) => _buildInitialAvatar(),
          errorWidget: (context, url, error) => _buildInitialAvatar(),
        ),
      );
    }

    return _buildInitialAvatar();
  }

  Widget _buildInitialAvatar() {
    return Center(
      child: Icon(
        LucideIcons.user,
        size: 60,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildBioStep(bool isDark) {
    return FadeInRight(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Text(
                  AppStrings.tellUsAboutYou,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppStrings.bioSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Full Name
              Text(
                AppStrings.fullName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.fullNameHint,
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: const Icon(LucideIcons.user),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // Bio
              Text(
                AppStrings.bio,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 150,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.bioHint,
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStep(bool isDark) {
    return FadeInRight(
      duration: const Duration(milliseconds: 500),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              AppStrings.whereAreYou,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.locationSubtitle,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Location icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.mapPin,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // Search input
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedLocationCity != null
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: _selectedLocationCity != null ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _locationController,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.searchCity,
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: const Icon(LucideIcons.search),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _selectedLocationCity != null
                          ? const Icon(LucideIcons.checkCircle, color: AppTheme.primaryColor)
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: _searchPlaces,
              ),
            ),

            // Search results or "No results" message
            if (_predictions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  itemBuilder: (context, index) {
                    final place = _predictions[index];
                    return ListTile(
                      leading: const Icon(
                        LucideIcons.mapPin,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        place.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: place.formattedAddress != null
                          ? Text(
                              place.formattedAddress!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => _selectPlace(place),
                    );
                  },
                ),
              ),

            // No results message (only show if searched and no results)
            if (_predictions.isEmpty &&
                !_isSearching &&
                _locationController.text.trim().length >= 2 &&
                _selectedLocationCity == null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.searchX,
                      size: 18,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No cities found. Try a different search.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Selected location confirmation
            if (_selectedLocationCity != null && _predictions.isEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedLocationCity!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        setState(() {
                          _selectedLocationCity = null;
                          _selectedPlaceId = null;
                          _locationController.clear();
                        });
                      },
                      color: AppTheme.primaryColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Powered by Google attribution
            FadeIn(
              delay: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://www.gstatic.com/images/branding/googlelogo/2x/googlelogo_color_74x24dp.png',
                      height: 16,
                      errorBuilder: (_, __, ___) => Text(
                        'Google',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.poweredByGoogle.replaceAll('Powered by ', ''),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (except on first step)
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _previousStep,
              icon: const Icon(LucideIcons.arrowLeft),
              label: Text(AppStrings.back),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : Colors.black54,
              ),
            )
          else
            const SizedBox(width: 100),

          const Spacer(),

          // Next/Finish button
          SizedBox(
            width: 140,
            height: 50,
            child: ElevatedButton(
              onPressed: _canProceed() && !_isCompleting ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 2 ? AppStrings.finish : AppStrings.next,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 2 ? LucideIcons.check : LucideIcons.arrowRight,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
