import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:quick_church/core/services/interfaces/i_auth_service.dart';
import 'package:quick_church/core/services/interfaces/i_profile_service.dart';
import 'package:quick_church/core/utils/kneel_logger.dart';
import 'package:quick_church/features/auth/domain/entities/user.dart' show User;
import 'package:quick_church/features/profile/domain/entities/profile.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';

/// Manages profile state throughout the application.
/// This is the global state for user profile data synced with Supabase.
@injectable
class ProfileCubit extends Cubit<ProfileState> {
  final IProfileService _profileService;
  final IAuthService _authService;
  StreamSubscription? _profileSubscription;
  String? _currentUserId;

  /// Timeout for Supabase profile operations (fail-safe)
  static const _profileTimeout = Duration(seconds: 15);

  /// Max retries for profile creation before assuming user is deleted
  static const _maxCreationRetries = 2;
  int _creationRetryCount = 0;

  /// Cached auth data for retry functionality
  _CachedAuthData? _cachedAuthData;

  /// PRODUCTION STABILITY: Flag to prevent operations during critical transitions
  /// Set to true during onboarding completion to prevent race conditions
  bool _isInTransition = false;

  /// Timestamp of last successful onboarding to prevent immediate re-triggering
  DateTime? _lastOnboardingCompletion;

  ProfileCubit(this._profileService, this._authService) : super(const ProfileInitial());

  /// Loads or creates a profile for the given user.
  /// Maps Firebase auth data to Supabase profile.
  ///
  /// On timeout/network error, emits [ProfileConnectionError] allowing retry.
  /// If profile cannot be created after retries, emits [ProfileNotFound] and triggers logout.
  ///
  /// PRODUCTION HARDENED:
  /// - Respects transition flag to prevent race conditions after onboarding
  /// - Skips reload if profile was just completed
  Future<void> loadProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    String? provider,
    String? phoneNumber,
    bool? emailVerified,
  }) async {
    // GUARD: Don't reload during transition (prevents race condition)
    if (_isInTransition) {
      KneelLogger.warn('loadProfile blocked - transition in progress', context: 'Profile');
      return;
    }

    // GUARD: Don't reload immediately after onboarding completion
    if (_lastOnboardingCompletion != null) {
      final elapsed = DateTime.now().difference(_lastOnboardingCompletion!);
      if (elapsed.inSeconds < 3) {
        KneelLogger.warn(
          'loadProfile blocked - onboarding just completed ${elapsed.inMilliseconds}ms ago',
          context: 'Profile',
        );
        return;
      }
    }

    KneelLogger.log('Loading profile for $uid', context: 'Profile');

    emit(const ProfileLoading());
    _currentUserId = uid;

    // Cache auth data for retry
    _cachedAuthData = _CachedAuthData(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      provider: provider,
      phoneNumber: phoneNumber,
      emailVerified: emailVerified,
    );

    // First, verify Firebase user still exists
    final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid != uid) {
      KneelLogger.warn('Firebase user mismatch or null - forcing logout', context: 'Profile');
      await _handleUserNotFound(uid, 'Firebase session invalid');
      return;
    }

    try {
      // Try to get existing profile with timeout
      Profile? existingProfile;
      bool isTimeout = false;

      try {
        existingProfile = await _profileService.getProfile(uid).timeout(
          _profileTimeout,
          onTimeout: () {
            KneelLogger.warn('getProfile timed out after ${_profileTimeout.inSeconds}s', context: 'Profile');
            isTimeout = true;
            return null;
          },
        );
      } catch (e) {
        KneelLogger.error('ProfileCubit.getProfile', e);

        // SELF-HEAL: Check for PostgrestException with User Not Found/Unauthorized
        if (_isPostgrestUserNotFoundError(e)) {
          await _handleUserNotFound(uid, 'PostgrestException: User not found or unauthorized');
          return;
        }

        // Check for permission/auth errors that indicate deleted user
        if (_isAuthError(e) || _isRLSError(e)) {
          await _handleUserNotFound(uid, 'Profile access denied');
          return;
        }

        // Check if it's a network-related error
        if (_isNetworkError(e)) {
          emit(ProfileConnectionError(
            message: 'Unable to connect. Please check your internet connection.',
            userId: uid,
          ));
          return;
        }
      }

      // Handle timeout case
      if (isTimeout) {
        emit(ProfileConnectionError(
          message: 'Connection timed out. Please try again.',
          userId: uid,
        ));
        return;
      }

      KneelLogger.log('Existing profile = ${existingProfile != null}', context: 'Profile');

      Profile profile;

      if (existingProfile == null) {
        // Create new profile if doesn't exist
        KneelLogger.log('Creating new profile...', context: 'Profile');

        // Safe-Save Rule: Sanitize phone number for new profile
        final sanitizedPhone = User.sanitizePhone(phoneNumber);

        try {
          profile = await _profileService.upsertProfile(
            uid: uid,
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
            provider: provider,
            phoneNumber: sanitizedPhone, // NULL if empty (Safe-Save Rule)
            emailVerified: emailVerified,
          ).timeout(_profileTimeout);

          _creationRetryCount = 0; // Reset on success
          KneelLogger.log('Created new profile for: $uid', context: 'Profile');
        } catch (e) {
          KneelLogger.error('ProfileCubit.createProfile', e);

          // SELF-HEAL: Check for PostgrestException with User Not Found/Unauthorized
          if (_isPostgrestUserNotFoundError(e)) {
            await _handleUserNotFound(uid, 'PostgrestException: Cannot create profile - user unauthorized');
            return;
          }

          // Check if creation failed due to RLS/permissions (user deleted scenario)
          if (_isAuthError(e) || _isRLSError(e)) {
            _creationRetryCount++;
            if (_creationRetryCount >= _maxCreationRetries) {
              await _handleUserNotFound(uid, 'Unable to create profile - account may be deleted');
              return;
            }
          }

          rethrow;
        }
      } else {
        // Update existing profile with latest auth data
        // IMPORTANT: Preserve existing bio, location, and googlePlaceId (Identity Sync)
        KneelLogger.log('Merging with existing profile (preserving bio/location)...', context: 'Profile');

        // PHONE MERGE with Safe-Save Rule:
        // Priority: authProviderPhone > existingDatabasePhone
        // Empty strings are converted to NULL to prevent unique constraint violations
        final mergedPhone = User.mergePhone(
          userInput: null, // No user input during profile load
          authProviderPhone: phoneNumber, // Phone from auth provider (Firebase/Google)
          existingDatabasePhone: existingProfile.phoneNumber,
        );

        profile = await _profileService.upsertProfile(
          uid: uid,
          email: email.isNotEmpty ? email : existingProfile.email,
          displayName: displayName ?? existingProfile.displayName,
          photoUrl: photoUrl ?? existingProfile.photoUrl,
          provider: provider ?? existingProfile.provider,
          phoneNumber: mergedPhone, // Uses Safe-Save merged value (NULL if empty)
          emailVerified: emailVerified ?? existingProfile.emailVerified,
          // MERGE: Keep existing user data, don't overwrite with defaults
          bio: existingProfile.bio,
          locationCity: existingProfile.locationCity,
          googlePlaceId: existingProfile.googlePlaceId,
        ).timeout(_profileTimeout);
        KneelLogger.log('Merged profile for: $uid', context: 'Profile');
      }

      // Check if onboarding is needed
      if (profile.needsOnboarding) {
        KneelLogger.log('Profile needs onboarding', context: 'Profile');
        emit(ProfileNeedsOnboarding(profile));
      } else {
        KneelLogger.log('Profile loaded successfully', context: 'Profile');
        emit(ProfileLoaded(profile));
      }

      // Start watching for real-time updates
      _watchProfile(uid);
    } on TimeoutException {
      KneelLogger.warn('Profile load timed out', context: 'Profile');
      emit(ProfileConnectionError(
        message: 'Connection timed out. Please try again.',
        userId: uid,
      ));
    } catch (e) {
      KneelLogger.error('ProfileCubit.loadProfile', e);

      // SELF-HEAL: Check for PostgrestException first (most specific)
      if (_isPostgrestUserNotFoundError(e)) {
        await _handleUserNotFound(uid, 'PostgrestException: Session invalid');
        return;
      }

      if (_isNetworkError(e)) {
        emit(ProfileConnectionError(
          message: 'Unable to connect. Please check your internet connection.',
          userId: uid,
        ));
      } else if (_isAuthError(e) || _isRLSError(e)) {
        await _handleUserNotFound(uid, 'Account access error');
      } else {
        emit(ProfileError(e.toString()));
      }
    }
  }

  /// Handles the case when user is not found (deleted from backend).
  ///
  /// SELF-HEALING LOGIC (Production):
  /// Automatically triggers forceLogoutAndClearAllData() to prevent zombie sessions.
  /// User is cleanly returned to auth screen for fresh sign-in.
  Future<void> _handleUserNotFound(String uid, String reason) async {
    KneelLogger.warn('=== SELF-HEALING TRIGGERED ===', context: 'Profile');
    KneelLogger.warn('User not found: $reason', context: 'Profile');
    KneelLogger.warn('Auto-clearing session to prevent zombie state...', context: 'Profile');

    // Emit state briefly so UI shows feedback (optional)
    emit(ProfileNotFound(
      userId: uid,
      message: 'Session expired. Signing out...',
    ));

    // Small delay for UI feedback
    await Future.delayed(const Duration(milliseconds: 300));

    // AUTO SELF-HEAL: Clear everything and return to auth
    await forceLogoutAndClearAllData();
  }

  /// Forces a complete logout, clearing all session data.
  /// Call this when user is deleted or session is corrupted.
  @Deprecated('Use forceLogoutAndClearAllData instead')
  Future<void> forceLogout() async {
    await forceLogoutAndClearAllData();
  }

  /// Self-Healing Session Reset: Nuclear option for zombie sessions.
  ///
  /// Clears ALL persistent data:
  /// 1. Calls AuthService.forceLogoutAndClearAllData()
  /// 2. Resets ProfileCubit to initial state
  ///
  /// Returns true if successful.
  Future<bool> forceLogoutAndClearAllData() async {
    KneelLogger.log('=== PROFILE CUBIT SELF-HEAL ===', context: 'Profile');

    bool success = true;

    try {
      // Call auth service to clear Firebase/Google/SharedPrefs
      success = await _authService.forceLogoutAndClearAllData();
    } catch (e) {
      KneelLogger.error('ProfileCubit.forceLogoutAndClearAllData', e);
      success = false;
    }

    // Clear local cubit state
    clear();

    KneelLogger.log('Profile cubit reset complete', context: 'Profile');
    return success;
  }

  /// Retries loading the profile using cached auth data.
  /// Call this when user taps "Retry Connection" button.
  Future<void> retryProfileLoad() async {
    if (_cachedAuthData == null) {
      KneelLogger.warn('No cached auth data for retry', context: 'Profile');
      return;
    }

    final cached = _cachedAuthData!;
    await loadProfile(
      uid: cached.uid,
      email: cached.email,
      displayName: cached.displayName,
      photoUrl: cached.photoUrl,
      provider: cached.provider,
      phoneNumber: cached.phoneNumber,
      emailVerified: cached.emailVerified,
    );
  }

  /// Refreshes the profile from Supabase.
  /// Use this to force a re-fetch of the latest data.
  Future<void> refreshProfile() async {
    if (_currentUserId == null) return;

    try {
      final profile = await _profileService.getProfile(_currentUserId!).timeout(_profileTimeout);
      if (profile != null) {
        if (profile.needsOnboarding) {
          emit(ProfileNeedsOnboarding(profile));
        } else {
          emit(ProfileLoaded(profile));
        }
        KneelLogger.log('Profile refreshed for: $_currentUserId', context: 'Profile');
      }
    } catch (e) {
      KneelLogger.error('ProfileCubit.refreshProfile', e);
    }
  }

  /// Syncs email verification status from Firebase to Supabase.
  /// Call this after user verifies their email.
  ///
  /// PRODUCTION HARDENED:
  /// - Returns early if Firebase user is null (prevents user-not-found errors)
  /// - Catches user-not-found specifically and triggers self-healing
  Future<bool> syncEmailVerificationStatus() async {
    // Guard 1: No cached user ID
    if (_currentUserId == null) {
      KneelLogger.warn('syncEmailVerificationStatus: No current user ID', context: 'Profile');
      return false;
    }

    // Guard 2: Firebase user is null - return early, do NOT attempt reload
    final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      KneelLogger.warn('syncEmailVerificationStatus: Firebase user is null - skipping sync', context: 'Profile');
      return false;
    }

    try {
      // Reload Firebase user to get latest verification status
      await firebaseUser.reload();
      final reloadedUser = firebase.FirebaseAuth.instance.currentUser;

      // Guard 3: User became null after reload (edge case)
      if (reloadedUser == null) {
        KneelLogger.warn('syncEmailVerificationStatus: User null after reload', context: 'Profile');
        return false;
      }

      if (reloadedUser.emailVerified) {
        // Update Supabase profile
        final updatedProfile = await _profileService.markEmailVerified(_currentUserId!);
        emit(ProfileLoaded(updatedProfile));
        KneelLogger.log('Email verification synced to Supabase', context: 'Profile');
        return true;
      }

      return false;
    } on firebase.FirebaseAuthException catch (e) {
      // SELF-HEAL: Specific handling for user-not-found
      if (e.code == 'user-not-found' || e.code == 'user-token-expired') {
        KneelLogger.warn(
          'syncEmailVerificationStatus: ${e.code} - triggering self-heal',
          context: 'Profile',
        );
        // Clean up zombie session gracefully
        await forceLogoutAndClearAllData();
        return false;
      }
      KneelLogger.error('ProfileCubit.syncEmailVerificationStatus', e);
      return false;
    } catch (e) {
      // Check for user-not-found in generic exceptions
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('user-not-found') || errorStr.contains('user not found')) {
        KneelLogger.warn(
          'syncEmailVerificationStatus: user-not-found detected - triggering self-heal',
          context: 'Profile',
        );
        await forceLogoutAndClearAllData();
        return false;
      }
      KneelLogger.error('ProfileCubit.syncEmailVerificationStatus', e);
      return false;
    }
  }

  /// Sends email verification and returns success status.
  ///
  /// PRODUCTION HARDENED:
  /// - Returns false instead of throwing if no user (graceful degradation)
  /// - Catches user-not-found errors and triggers self-healing
  Future<bool> resendEmailVerification() async {
    try {
      final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        KneelLogger.warn('resendEmailVerification: No Firebase user', context: 'Profile');
        return false; // Graceful degradation instead of throwing
      }
      if (firebaseUser.emailVerified) {
        // Already verified - sync to Supabase
        await syncEmailVerificationStatus();
        return true;
      }

      await firebaseUser.sendEmailVerification();
      KneelLogger.log('Verification email sent', context: 'Profile');
      return true;
    } on firebase.FirebaseAuthException catch (e) {
      // SELF-HEAL: Handle user-not-found gracefully
      if (e.code == 'user-not-found' || e.code == 'user-token-expired') {
        KneelLogger.warn('resendEmailVerification: ${e.code} - triggering self-heal', context: 'Profile');
        await forceLogoutAndClearAllData();
        return false;
      }
      KneelLogger.error('ProfileCubit.resendEmailVerification', e);
      rethrow;
    } catch (e) {
      KneelLogger.error('ProfileCubit.resendEmailVerification', e);
      rethrow;
    }
  }

  /// Watches profile for real-time updates.
  void _watchProfile(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = _profileService.watchProfile(uid).listen(
      (profile) {
        if (profile != null && state is! ProfileLoading && state is! ProfileUpdating) {
          if (profile.needsOnboarding) {
            emit(ProfileNeedsOnboarding(profile));
          } else {
            emit(ProfileLoaded(profile));
          }
        }
      },
      onError: (e) {
        KneelLogger.error('ProfileCubit.watchProfile', e);
      },
    );
  }

  /// Completes the onboarding process (ATOMIC).
  ///
  /// Performs an upsert on the profiles table with bio, location, and display name.
  /// Validates data BEFORE and AFTER the upsert to ensure atomicity.
  ///
  /// PRODUCTION HARDENED:
  /// - Uses transition flag to prevent race conditions
  /// - Tracks completion timestamp to prevent double-triggers
  /// - Validates Firebase session before proceeding
  ///
  /// If the Supabase upsert fails, the user will NOT proceed to Home.
  Future<void> completeOnboarding({
    required String displayName,
    required String bio,
    required String locationCity,
    required String googlePlaceId,
    String? photoUrl,
  }) async {
    // GUARD: Prevent double-completion within 2 seconds
    if (_lastOnboardingCompletion != null) {
      final elapsed = DateTime.now().difference(_lastOnboardingCompletion!);
      if (elapsed.inSeconds < 2) {
        KneelLogger.warn('Onboarding completion blocked - too soon after last completion', context: 'Profile');
        return;
      }
    }

    // GUARD: Prevent operations during transition
    if (_isInTransition) {
      KneelLogger.warn('Onboarding completion blocked - transition in progress', context: 'Profile');
      return;
    }

    final currentState = state;
    Profile? currentProfile;

    if (currentState is ProfileNeedsOnboarding) {
      currentProfile = currentState.profile;
    } else if (currentState is ProfileLoaded) {
      currentProfile = currentState.profile;
    }

    if (currentProfile == null || _currentUserId == null) {
      emit(const ProfileError('No profile to update'));
      return;
    }

    // CRITICAL: Verify Firebase session is still valid before proceeding
    final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid != _currentUserId) {
      KneelLogger.warn('Firebase session invalid during onboarding - aborting', context: 'Profile');
      emit(const ProfileError('Session expired. Please sign in again.'));
      await _handleUserNotFound(_currentUserId!, 'Firebase session invalid during onboarding');
      return;
    }

    // PRE-VALIDATION: Validate input data before attempting upsert
    if (displayName.trim().isEmpty) {
      emit(const ProfileError('Display name is required'));
      emit(ProfileNeedsOnboarding(currentProfile));
      return;
    }
    if (locationCity.trim().isEmpty || googlePlaceId.trim().isEmpty) {
      emit(const ProfileError('Location is required'));
      emit(ProfileNeedsOnboarding(currentProfile));
      return;
    }

    // Set transition flag
    _isInTransition = true;
    emit(ProfileUpdating(currentProfile));

    try {
      // Safe-Save Rule: Sanitize phone number before upsert
      final sanitizedPhone = User.sanitizePhone(currentProfile.phoneNumber);

      // ATOMIC UPSERT: Ensure all data is saved atomically
      final updatedProfile = await _profileService.upsertProfile(
        uid: _currentUserId!,
        email: currentProfile.email,
        displayName: displayName.trim(),
        photoUrl: photoUrl ?? currentProfile.photoUrl,
        provider: currentProfile.provider,
        phoneNumber: sanitizedPhone, // NULL if empty (Safe-Save Rule)
        bio: bio.trim(),
        locationCity: locationCity.trim(),
        googlePlaceId: googlePlaceId.trim(),
        emailVerified: currentProfile.emailVerified,
      ).timeout(_profileTimeout);

      // POST-VALIDATION: Verify the profile is complete before navigating
      final validationError = updatedProfile.validateForOnboarding();
      if (validationError != null) {
        KneelLogger.error('ProfileCubit.completeOnboarding', 'Post-validation failed: $validationError');
        emit(ProfileError('Failed to save profile: $validationError'));
        emit(ProfileNeedsOnboarding(currentProfile));
        _isInTransition = false;
        return;
      }

      // Final check: Ensure profile is complete
      if (!updatedProfile.isProfileComplete) {
        KneelLogger.error('ProfileCubit.completeOnboarding', 'Profile not complete after upsert');
        emit(const ProfileError('Profile data incomplete. Please try again.'));
        emit(ProfileNeedsOnboarding(currentProfile));
        _isInTransition = false;
        return;
      }

      // SUCCESS: Record completion time and emit loaded state
      _lastOnboardingCompletion = DateTime.now();
      KneelLogger.log('Onboarding completed for: $_currentUserId', context: 'Profile');
      emit(ProfileLoaded(updatedProfile));

      // Clear transition flag after a brief delay to allow UI to settle
      Future.delayed(const Duration(milliseconds: 500), () {
        _isInTransition = false;
      });
    } on TimeoutException {
      _isInTransition = false;
      KneelLogger.error('ProfileCubit.completeOnboarding', 'Timeout during onboarding');
      emit(const ProfileError('Connection timed out. Please try again.'));
      emit(ProfileNeedsOnboarding(currentProfile));
    } catch (e) {
      _isInTransition = false;
      KneelLogger.error('ProfileCubit.completeOnboarding', e);
      emit(ProfileError(e.toString()));
      // CRITICAL: Do NOT proceed to Home on failure - stay on onboarding
      emit(ProfileNeedsOnboarding(currentProfile));
    }
  }

  /// Updates the user's bio.
  Future<void> updateBio(String bio) async {
    await _updateField(() => _profileService.updateBio(_currentUserId!, bio));
  }

  /// Updates the user's location.
  Future<void> updateLocation(String locationCity, String googlePlaceId) async {
    await _updateField(
      () => _profileService.updateLocation(_currentUserId!, locationCity, googlePlaceId),
    );
  }

  /// Updates the user's photo.
  Future<void> updatePhoto(String photoUrl) async {
    await _updateField(() => _profileService.updatePhotoUrl(_currentUserId!, photoUrl));
  }

  /// Updates the user's display name.
  Future<void> updateDisplayName(String displayName) async {
    await _updateField(
      () => _profileService.updateProfile(uid: _currentUserId!, displayName: displayName),
    );
  }

  /// Marks email as verified in Supabase.
  Future<void> markEmailVerified() async {
    await _updateField(() => _profileService.markEmailVerified(_currentUserId!));
  }

  /// Helper method to update a field.
  Future<void> _updateField(Future<Profile> Function() updateFn) async {
    if (_currentUserId == null) return;

    final currentState = state;
    Profile? currentProfile;

    if (currentState is ProfileLoaded) {
      currentProfile = currentState.profile;
    } else if (currentState is ProfileNeedsOnboarding) {
      currentProfile = currentState.profile;
    }

    if (currentProfile == null) return;

    emit(ProfileUpdating(currentProfile));

    try {
      final updatedProfile = await updateFn().timeout(_profileTimeout);
      emit(ProfileLoaded(updatedProfile));
    } catch (e) {
      KneelLogger.error('ProfileCubit.updateField', e);
      emit(ProfileError(e.toString()));
      emit(ProfileLoaded(currentProfile));
    }
  }

  /// Gets the current profile if loaded.
  Profile? get currentProfile {
    final currentState = state;
    if (currentState is ProfileLoaded) return currentState.profile;
    if (currentState is ProfileNeedsOnboarding) return currentState.profile;
    if (currentState is ProfileUpdating) return currentState.currentProfile;
    return null;
  }

  /// Gets the current user ID.
  String? get currentUserId => _currentUserId;

  /// Checks if an error is network-related
  bool _isNetworkError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('host lookup') ||
        errorStr.contains('unreachable');
  }

  /// Checks if an error is auth/permission related (might indicate deleted user)
  bool _isAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('user-not-found') ||
        errorStr.contains('user not found') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('permission denied') ||
        errorStr.contains('unauthenticated');
  }

  /// Checks if an error is RLS (Row Level Security) related
  bool _isRLSError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('rls') ||
        errorStr.contains('row-level security') ||
        errorStr.contains('42501') || // PostgreSQL permission denied
        errorStr.contains('policy');
  }

  /// Checks if a PostgrestException indicates user not found or unauthorized.
  /// This is the primary trigger for production self-healing.
  bool _isPostgrestUserNotFoundError(dynamic error) {
    if (error is PostgrestException) {
      final code = error.code?.toLowerCase() ?? '';
      final message = error.message.toLowerCase();

      // Check for common "user not found" patterns
      final isUserNotFound = message.contains('user not found') ||
          message.contains('no rows') ||
          message.contains('not found') ||
          code == 'pgrst116'; // PostgREST: No rows returned

      // Check for unauthorized/permission errors
      final isUnauthorized = message.contains('unauthorized') ||
          message.contains('permission denied') ||
          message.contains('jwt') ||
          code == '42501' || // PostgreSQL permission denied
          code == 'pgrst301'; // PostgREST: JWT error

      if (isUserNotFound || isUnauthorized) {
        KneelLogger.warn(
          'PostgrestException detected: code=$code, message=${error.message}',
          context: 'Profile',
        );
        return true;
      }
    }
    return false;
  }

  // ============================================================================
  // PHOTO UPLOAD
  // ============================================================================

  /// Uploads a profile photo with cropping and compression.
  /// Returns the new photo URL on success, null on cancel/failure.
  Future<String?> uploadProfilePhoto({ImageSource source = ImageSource.gallery}) async {
    if (_currentUserId == null) return null;

    final currentState = state;
    Profile? currentProfile;

    if (currentState is ProfileLoaded) {
      currentProfile = currentState.profile;
    } else if (currentState is ProfileNeedsOnboarding) {
      currentProfile = currentState.profile;
    }

    try {
      // Step 1: Pick image
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (pickedFile == null) return null;

      // Step 2: Crop to 1:1 square
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: const Color(0xFF673AB7),
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile == null) return null;

      // Emit uploading state
      if (currentProfile != null) {
        emit(ProfileUpdating(currentProfile));
      }

      // Step 3: Compress to under 500KB for global users
      Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        croppedFile.path,
        minWidth: 512,
        minHeight: 512,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      // Further compress if still too large
      if (compressedBytes != null && compressedBytes.length > 500 * 1024) {
        compressedBytes = await FlutterImageCompress.compressWithFile(
          croppedFile.path,
          minWidth: 400,
          minHeight: 400,
          quality: 60,
          format: CompressFormat.jpeg,
        );
      }

      if (compressedBytes == null) {
        throw Exception('Failed to compress image');
      }

      KneelLogger.log('Compressed image size: ${compressedBytes.length} bytes', context: 'Profile');

      // Step 4: Upload to Supabase Storage
      final photoUrl = await _profileService.uploadProfilePhoto(
        _currentUserId!,
        compressedBytes,
      );

      // Step 5: Update profile with new photo URL
      final updatedProfile = await _profileService.updatePhotoUrl(
        _currentUserId!,
        photoUrl,
      );

      if (updatedProfile.needsOnboarding) {
        emit(ProfileNeedsOnboarding(updatedProfile));
      } else {
        emit(ProfileLoaded(updatedProfile));
      }

      KneelLogger.log('Profile photo updated successfully', context: 'Profile');
      return photoUrl;
    } catch (e) {
      KneelLogger.error('ProfileCubit.uploadProfilePhoto', e);
      // Restore previous state
      if (currentProfile != null) {
        if (currentProfile.needsOnboarding) {
          emit(ProfileNeedsOnboarding(currentProfile));
        } else {
          emit(ProfileLoaded(currentProfile));
        }
      }
      rethrow;
    }
  }

  // ============================================================================
  // ACCOUNT MANAGEMENT (GDPR/POPIA COMPLIANCE)
  // ============================================================================

  /// Deletes the user's account completely (GDPR/POPIA compliant).
  /// 1. Deletes user's files from Supabase Storage
  /// 2. Deletes user's profile from Supabase
  /// 3. Deletes Firebase Auth user
  Future<void> deleteAccount() async {
    if (_currentUserId == null) {
      throw Exception('No user ID available');
    }

    final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('No Firebase user signed in');
    }

    try {
      // Step 1: Delete storage files (avatars folder)
      await _profileService.deleteUserStorageFiles(_currentUserId!);
      KneelLogger.log('Deleted storage files for: $_currentUserId', context: 'Profile');

      // Step 2: Delete profile from Supabase
      await _profileService.deleteProfile(_currentUserId!);
      KneelLogger.log('Deleted Supabase profile for: $_currentUserId', context: 'Profile');

      // Step 3: Delete Firebase Auth user
      await firebaseUser.delete();
      KneelLogger.log('Deleted Firebase user: ${firebaseUser.uid}', context: 'Profile');

      // Clear local state
      clear();
    } catch (e) {
      KneelLogger.error('ProfileCubit.deleteAccount', e);
      rethrow;
    }
  }

  /// Clears the profile state (on logout).
  void clear() {
    _profileSubscription?.cancel();
    _currentUserId = null;
    _cachedAuthData = null;
    _creationRetryCount = 0;
    _isInTransition = false;
    _lastOnboardingCompletion = null;
    emit(const ProfileInitial());
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}

/// Internal class to cache auth data for retry functionality
class _CachedAuthData {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? provider;
  final String? phoneNumber;
  final bool? emailVerified;

  _CachedAuthData({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.provider,
    this.phoneNumber,
    this.emailVerified,
  });
}
