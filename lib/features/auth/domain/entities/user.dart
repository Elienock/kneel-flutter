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
