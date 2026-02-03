import 'package:equatable/equatable.dart';

/// Represents an authenticated user in the application.
class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final AuthProvider provider;
  final DateTime createdAt;
  final bool isEmailVerified;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.provider,
    required this.createdAt,
    this.isEmailVerified = false,
  });

  /// Sanitizes a phone number value.
  /// Returns null if the value is null or empty (Safe-Save Rule).
  /// This prevents unique constraint violations on empty strings in the database.
  static String? sanitizePhone(String? phone) {
    if (phone == null) return null;
    final trimmed = phone.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Merges phone numbers with priority: userInput > authProvider > existing.
  /// Returns null if all values are null/empty (Safe-Save Rule).
  static String? mergePhone({
    String? userInput,
    String? authProviderPhone,
    String? existingDatabasePhone,
  }) {
    // Priority 1: User explicitly entered a phone number
    final sanitizedInput = sanitizePhone(userInput);
    if (sanitizedInput != null) return sanitizedInput;

    // Priority 2: Phone from auth provider (Google/Firebase)
    final sanitizedAuth = sanitizePhone(authProviderPhone);
    if (sanitizedAuth != null) return sanitizedAuth;

    // Priority 3: Existing phone in database
    return sanitizePhone(existingDatabasePhone);
  }

  /// Creates a copy of this user with the given fields replaced.
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    AuthProvider? provider,
    DateTime? createdAt,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, phoneNumber, provider, createdAt, isEmailVerified];
}

/// The authentication provider used to sign in.
enum AuthProvider {
  google,
  phone,
  email,
  biometric,
  anonymous,
}
