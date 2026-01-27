import 'package:equatable/equatable.dart';
import 'package:quick_church/features/auth/domain/entities/user.dart';

/// Represents the authentication state of the application.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any authentication check.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state during authentication operations.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when user is successfully authenticated.
class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// State when user is not authenticated.
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// State when an authentication error occurs.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
