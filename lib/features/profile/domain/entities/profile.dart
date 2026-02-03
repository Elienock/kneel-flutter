import 'package:equatable/equatable.dart';

/// Profile entity matching the Supabase 'public.profiles' schema.
class Profile extends Equatable {
  final String id;
  final String email;
  final String? phoneNumber;
  final String displayName;
  final String? photoUrl;
  final String provider;
  final String bio;
  final String? locationCity;
  final String? googlePlaceId;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Insights & Streak fields
  final int answeredPrayersCount;
  final int currentStreak;
  final int longestStreak;

  const Profile({
    required this.id,
    required this.email,
    this.phoneNumber,
    required this.displayName,
    this.photoUrl,
    required this.provider,
    this.bio = 'I am Holy and consecrated to GOD',
    this.locationCity,
    this.googlePlaceId,
    this.emailVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.answeredPrayersCount = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  /// Creates a Profile from Supabase JSON response.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      displayName: json['display_name'] as String? ?? 'Prayer Warrior',
      photoUrl: json['photo_url'] as String?,
      provider: json['provider'] as String? ?? 'unknown',
      bio: json['bio'] as String? ?? 'I am Holy and consecrated to GOD',
      locationCity: json['location_city'] as String?,
      googlePlaceId: json['google_place_id'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      answeredPrayersCount: json['answered_prayers_count'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
    );
  }

  /// Converts Profile to JSON for Supabase upsert.
  ///
  /// IMPORTANT: phone_number is sanitized to prevent unique constraint violations.
  /// Empty strings are converted to null and excluded from the map.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'provider': provider,
      'bio': bio,
      'location_city': locationCity,
      'google_place_id': googlePlaceId,
      'email_verified': emailVerified,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Only include phone_number if it has a real value (not null or empty)
    // This prevents unique constraint violations on empty strings
    final sanitizedPhone = phoneNumber?.trim();
    if (sanitizedPhone != null && sanitizedPhone.isNotEmpty) {
      map['phone_number'] = sanitizedPhone;
    }
    // If phone is null/empty, we DON'T include it - let the DB keep existing value or NULL

    return map;
  }

  /// Creates a copy with the given fields replaced.
  Profile copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    String? provider,
    String? bio,
    String? locationCity,
    String? googlePlaceId,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? answeredPrayersCount,
    int? currentStreak,
    int? longestStreak,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      bio: bio ?? this.bio,
      locationCity: locationCity ?? this.locationCity,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      answeredPrayersCount: answeredPrayersCount ?? this.answeredPrayersCount,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }

  /// Whether the user needs to complete onboarding.
  bool get needsOnboarding => locationCity == null || locationCity!.isEmpty;

  /// Validates that all required fields for navigation to Home are present.
  /// Used by Smart Router to ensure data integrity before navigation.
  bool get isProfileComplete =>
      id.isNotEmpty &&
      displayName.isNotEmpty &&
      locationCity != null &&
      locationCity!.isNotEmpty;

  /// Validates profile data integrity for onboarding completion.
  /// Returns null if valid, or error message if invalid.
  String? validateForOnboarding() {
    if (id.isEmpty) return 'Profile ID is missing';
    if (displayName.isEmpty) return 'Display name is required';
    if (locationCity == null || locationCity!.isEmpty) {
      return 'Location is required';
    }
    return null;
  }

  /// Whether the user signed in with phone (skip email verification).
  bool get isPhoneUser => provider == 'phone';

  /// Whether the user signed in with Google (email already verified by Google).
  bool get isGoogleUser => provider == 'google';

  /// Whether the user signed in with email/password.
  bool get isEmailUser => provider == 'email' || provider == 'password';

  /// Whether to show email verification banner.
  /// Only shows for email/password users who haven't verified their email.
  /// Google users are already verified, phone users don't need email verification.
  bool get showEmailVerificationBanner =>
      isEmailUser && !emailVerified && email.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        email,
        phoneNumber,
        displayName,
        photoUrl,
        provider,
        bio,
        locationCity,
        googlePlaceId,
        emailVerified,
        createdAt,
        updatedAt,
        answeredPrayersCount,
        currentStreak,
        longestStreak,
      ];
}
