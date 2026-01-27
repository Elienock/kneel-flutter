import 'package:equatable/equatable.dart';

/// Represents an authenticated user in the application.
class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final AuthProvider provider;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.provider,
    required this.createdAt,
  });

  /// Creates a copy of this user with the given fields replaced.
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AuthProvider? provider,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, provider, createdAt];
}

/// The authentication provider used to sign in.
enum AuthProvider {
  google,
  apple,
  biometric,
  anonymous,
}
