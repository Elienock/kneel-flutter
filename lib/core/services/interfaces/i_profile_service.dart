import 'dart:typed_data';
import 'package:quick_church/features/profile/domain/entities/profile.dart';

/// Abstract interface for Supabase profile management.
abstract class IProfileService {
  // ============================================================================
  // STORAGE OPERATIONS
  // ============================================================================

  /// Uploads a profile photo to Supabase Storage.
  /// Returns the public URL with cache-busting timestamp.
  Future<String> uploadProfilePhoto(String uid, Uint8List imageBytes);

  /// Deletes all files in the user's storage folder.
  Future<void> deleteUserStorageFiles(String uid);

  // ============================================================================
  // PROFILE OPERATIONS
  // ============================================================================
  /// Creates or updates a user profile in Supabase.
  /// Called after successful Firebase authentication to sync user data.
  Future<Profile> upsertProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    String? provider,
    String? phoneNumber,
    String? bio,
    String? locationCity,
    String? googlePlaceId,
    bool? emailVerified,
  });

  /// Gets a user profile from Supabase by UID.
  Future<Profile?> getProfile(String uid);

  /// Updates specific profile fields.
  Future<Profile> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? locationCity,
    String? googlePlaceId,
    bool? emailVerified,
  });

  /// Updates the user's bio.
  Future<Profile> updateBio(String uid, String bio);

  /// Updates the user's location.
  Future<Profile> updateLocation(String uid, String locationCity, String googlePlaceId);

  /// Updates the user's photo URL.
  Future<Profile> updatePhotoUrl(String uid, String photoUrl);

  /// Marks email as verified.
  Future<Profile> markEmailVerified(String uid);

  /// Deletes a user profile from Supabase.
  Future<void> deleteProfile(String uid);

  /// Stream of profile changes for real-time updates.
  Stream<Profile?> watchProfile(String uid);
}
