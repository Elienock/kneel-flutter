import 'dart:async';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quick_church/core/services/interfaces/i_profile_service.dart';
import 'package:quick_church/core/utils/kneel_logger.dart';
import 'package:quick_church/features/profile/domain/entities/profile.dart';

/// Implementation of [IProfileService] using Supabase.
@LazySingleton(as: IProfileService)
class SupabaseProfileService implements IProfileService {
  SupabaseClient get _client => Supabase.instance.client;

  /// The Supabase Storage bucket name for avatars.
  static const String _avatarBucket = 'avatars';

  // ============================================================================
  // STORAGE OPERATIONS
  // ============================================================================

  @override
  Future<String> uploadProfilePhoto(String uid, Uint8List imageBytes) async {
    try {
      final filePath = '$uid/profile_avatar.jpg';

      // Upload with upsert to overwrite existing file
      await _client.storage.from(_avatarBucket).uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage.from(_avatarBucket).getPublicUrl(filePath);

      // Append timestamp for cache busting
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cacheBustedUrl = '$publicUrl?v=$timestamp';

      KneelLogger.log('Profile photo uploaded: $cacheBustedUrl');
      return cacheBustedUrl;
    } catch (e) {
      KneelLogger.error('SupabaseProfileService.uploadProfilePhoto', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteUserStorageFiles(String uid) async {
    try {
      // List all files in the user's folder
      final files = await _client.storage.from(_avatarBucket).list(path: uid);

      if (files.isNotEmpty) {
        // Build list of file paths to delete
        final filePaths = files.map((f) => '$uid/${f.name}').toList();

        // Delete all files in the user's folder
        await _client.storage.from(_avatarBucket).remove(filePaths);
        KneelLogger.log('Deleted ${filePaths.length} storage files for user: $uid');
      }
    } catch (e) {
      KneelLogger.error('SupabaseProfileService.deleteUserStorageFiles', e);
      // Don't rethrow - storage deletion failure shouldn't block account deletion
    }
  }

  // ============================================================================
  // PROFILE OPERATIONS
  // ============================================================================

  @override
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
  }) async {
    try {
      final data = {
        'id': uid,
        'email': email,
        'display_name': displayName ?? 'Prayer Warrior',
        'photo_url': photoUrl,
        'provider': provider,
        'phone_number': phoneNumber,
        'bio': bio ?? 'I am Holy and consecrated to GOD',
        'location_city': locationCity,
        'google_place_id': googlePlaceId,
        'email_verified': emailVerified ?? false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      // Remove null values to avoid overwriting existing data
      data.removeWhere((key, value) => value == null && key != 'id' && key != 'email');

      final response = await _client
          .from('profiles')
          .upsert(data)
          .select()
          .single();

      KneelLogger.profileSynced(uid);
      return Profile.fromJson(response);
    } catch (e) {
      KneelLogger.error('SupabaseProfileService.upsertProfile', e);
      rethrow;
    }
  }

  @override
  Future<Profile?> getProfile(String uid) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      KneelLogger.error('SupabaseProfileService.getProfile', e);
      return null;
    }
  }

  @override
  Future<Profile> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? locationCity,
    String? googlePlaceId,
    bool? emailVerified,
  }) async {
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (displayName != null) data['display_name'] = displayName;
      if (photoUrl != null) data['photo_url'] = photoUrl;
      if (bio != null) data['bio'] = bio;
      if (locationCity != null) data['location_city'] = locationCity;
      if (googlePlaceId != null) data['google_place_id'] = googlePlaceId;
      if (emailVerified != null) data['email_verified'] = emailVerified;

      final response = await _client
          .from('profiles')
          .update(data)
          .eq('id', uid)
          .select()
          .single();

      KneelLogger.log('Profile updated for: $uid');
      return Profile.fromJson(response);
    } catch (e) {
      KneelLogger.error('SupabaseProfileService.updateProfile', e);
      rethrow;
    }
  }

  @override
  Future<Profile> updateBio(String uid, String bio) async {
    return updateProfile(uid: uid, bio: bio);
  }

  @override
  Future<Profile> updateLocation(String uid, String locationCity, String googlePlaceId) async {
    return updateProfile(
      uid: uid,
      locationCity: locationCity,
      googlePlaceId: googlePlaceId,
    );
  }

  @override
  Future<Profile> updatePhotoUrl(String uid, String photoUrl) async {
    return updateProfile(uid: uid, photoUrl: photoUrl);
  }

  @override
  Future<Profile> markEmailVerified(String uid) async {
    return updateProfile(uid: uid, emailVerified: true);
  }

  @override
  Future<void> deleteProfile(String uid) async {
    try {
      await _client.from('profiles').delete().eq('id', uid);
      KneelLogger.log('Profile deleted: $uid');
    } catch (e) {
      KneelLogger.error('SupabaseProfileService.deleteProfile', e);
      rethrow;
    }
  }

  @override
  Stream<Profile?> watchProfile(String uid) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((list) {
          if (list.isEmpty) return null;
          return Profile.fromJson(list.first);
        });
  }
}
