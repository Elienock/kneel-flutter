import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:quick_church/core/services/interfaces/i_profile_service.dart';
import 'package:quick_church/core/utils/debug_logger.dart';
import 'package:quick_church/features/profile/domain/entities/profile.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';

/// Manages profile state throughout the application.
/// This is the global state for user profile data synced with Supabase.
@injectable
class ProfileCubit extends Cubit<ProfileState> {
  final IProfileService _profileService;
  StreamSubscription? _profileSubscription;
  String? _currentUserId;

  ProfileCubit(this._profileService) : super(const ProfileInitial());

  /// Loads or creates a profile for the given user.
  /// Maps Firebase auth data to Supabase profile.
  Future<void> loadProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    String? provider,
    String? phoneNumber,
    bool? emailVerified,
  }) async {
    emit(const ProfileLoading());
    _currentUserId = uid;

    try {
      // First, try to get existing profile
      var profile = await _profileService.getProfile(uid);

      if (profile == null) {
        // Create new profile if doesn't exist
        profile = await _profileService.upsertProfile(
          uid: uid,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          provider: provider,
          phoneNumber: phoneNumber,
          emailVerified: emailVerified,
        );
        DebugLogger.log('Created new profile for: $uid');
      } else {
        // Update existing profile with latest auth data
        // Preserve existing bio, location, and googlePlaceId
        profile = await _profileService.upsertProfile(
          uid: uid,
          email: email.isNotEmpty ? email : profile.email,
          displayName: displayName ?? profile.displayName,
          photoUrl: photoUrl ?? profile.photoUrl,
          provider: provider ?? profile.provider,
          phoneNumber: phoneNumber ?? profile.phoneNumber,
          emailVerified: emailVerified ?? profile.emailVerified,
          bio: profile.bio,
          locationCity: profile.locationCity,
          googlePlaceId: profile.googlePlaceId,
        );
        DebugLogger.log('Updated profile for: $uid');
      }

      // Check if onboarding is needed
      if (profile.needsOnboarding) {
        emit(ProfileNeedsOnboarding(profile));
      } else {
        emit(ProfileLoaded(profile));
      }

      // Start watching for real-time updates
      _watchProfile(uid);
    } catch (e) {
      DebugLogger.error('ProfileCubit.loadProfile', e);
      emit(ProfileError(e.toString()));
    }
  }

  /// Refreshes the profile from Supabase.
  /// Use this to force a re-fetch of the latest data.
  Future<void> refreshProfile() async {
    if (_currentUserId == null) return;

    try {
      final profile = await _profileService.getProfile(_currentUserId!);
      if (profile != null) {
        if (profile.needsOnboarding) {
          emit(ProfileNeedsOnboarding(profile));
        } else {
          emit(ProfileLoaded(profile));
        }
        DebugLogger.log('Profile refreshed for: $_currentUserId');
      }
    } catch (e) {
      DebugLogger.error('ProfileCubit.refreshProfile', e);
    }
  }

  /// Syncs email verification status from Firebase to Supabase.
  /// Call this after user verifies their email.
  Future<bool> syncEmailVerificationStatus() async {
    if (_currentUserId == null) return false;

    try {
      // Reload Firebase user to get latest verification status
      final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;

      await firebaseUser.reload();
      final reloadedUser = firebase.FirebaseAuth.instance.currentUser;

      if (reloadedUser != null && reloadedUser.emailVerified) {
        // Update Supabase profile
        final updatedProfile = await _profileService.markEmailVerified(_currentUserId!);
        emit(ProfileLoaded(updatedProfile));
        DebugLogger.log('Email verification synced to Supabase');
        return true;
      }

      return false;
    } catch (e) {
      DebugLogger.error('ProfileCubit.syncEmailVerificationStatus', e);
      return false;
    }
  }

  /// Sends email verification and returns success status.
  Future<bool> resendEmailVerification() async {
    try {
      final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user signed in');
      }
      if (firebaseUser.emailVerified) {
        // Already verified - sync to Supabase
        await syncEmailVerificationStatus();
        return true;
      }

      await firebaseUser.sendEmailVerification();
      DebugLogger.log('Verification email sent');
      return true;
    } catch (e) {
      DebugLogger.error('ProfileCubit.resendEmailVerification', e);
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
        DebugLogger.error('ProfileCubit.watchProfile', e);
      },
    );
  }

  /// Completes the onboarding process.
  /// Performs an upsert on the profiles table with bio, location, and display name.
  Future<void> completeOnboarding({
    required String displayName,
    required String bio,
    required String locationCity,
    required String googlePlaceId,
    String? photoUrl,
  }) async {
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

    emit(ProfileUpdating(currentProfile));

    try {
      // Use upsert to ensure all data is saved atomically
      final updatedProfile = await _profileService.upsertProfile(
        uid: _currentUserId!,
        email: currentProfile.email,
        displayName: displayName,
        photoUrl: photoUrl ?? currentProfile.photoUrl,
        provider: currentProfile.provider,
        phoneNumber: currentProfile.phoneNumber,
        bio: bio,
        locationCity: locationCity,
        googlePlaceId: googlePlaceId,
        emailVerified: currentProfile.emailVerified,
      );

      DebugLogger.log('Onboarding completed for: $_currentUserId');
      emit(ProfileLoaded(updatedProfile));
    } catch (e) {
      DebugLogger.error('ProfileCubit.completeOnboarding', e);
      emit(ProfileError(e.toString()));
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
      final updatedProfile = await updateFn();
      emit(ProfileLoaded(updatedProfile));
    } catch (e) {
      DebugLogger.error('ProfileCubit.updateField', e);
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

      DebugLogger.log('Compressed image size: ${compressedBytes.length} bytes');

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

      DebugLogger.log('Profile photo updated successfully');
      return photoUrl;
    } catch (e) {
      DebugLogger.error('ProfileCubit.uploadProfilePhoto', e);
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
      DebugLogger.log('Deleted storage files for: $_currentUserId');

      // Step 2: Delete profile from Supabase
      await _profileService.deleteProfile(_currentUserId!);
      DebugLogger.log('Deleted Supabase profile for: $_currentUserId');

      // Step 3: Delete Firebase Auth user
      await firebaseUser.delete();
      DebugLogger.log('Deleted Firebase user: ${firebaseUser.uid}');

      // Clear local state
      clear();
    } catch (e) {
      DebugLogger.error('ProfileCubit.deleteAccount', e);
      rethrow;
    }
  }

  /// Clears the profile state (on logout).
  void clear() {
    _profileSubscription?.cancel();
    _currentUserId = null;
    emit(const ProfileInitial());
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}
