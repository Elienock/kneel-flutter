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
