import 'package:equatable/equatable.dart';
import 'package:quick_church/features/profile/domain/entities/profile.dart';

/// Represents the profile state in the application.
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state before profile is loaded.
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading state during profile operations.
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// State when profile is successfully loaded.
class ProfileLoaded extends ProfileState {
  final Profile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// State when user needs to complete onboarding.
class ProfileNeedsOnboarding extends ProfileState {
  final Profile profile;

  const ProfileNeedsOnboarding(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// State when profile load or update fails.
class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State during profile update operation.
class ProfileUpdating extends ProfileState {
  final Profile currentProfile;

  const ProfileUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

/// State when profile connection fails (timeout/network error).
/// Allows user to retry without full re-authentication.
class ProfileConnectionError extends ProfileState {
  final String message;
  final String? userId;

  const ProfileConnectionError({
    required this.message,
    this.userId,
  });

  @override
  List<Object?> get props => [message, userId];
}

/// State when profile is not found in database (user deleted from backend).
/// This triggers a force logout to clear zombie sessions.
class ProfileNotFound extends ProfileState {
  final String userId;
  final String message;

  const ProfileNotFound({
    required this.userId,
    this.message = 'Your account was not found. Please sign in again.',
  });

  @override
  List<Object?> get props => [userId, message];
}
