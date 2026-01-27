import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:quick_church/core/services/interfaces/i_auth_service.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_state.dart';

/// Manages authentication state throughout the application.
@injectable
class AuthCubit extends Cubit<AuthState> {
  final IAuthService _authService;
  StreamSubscription? _authSubscription;

  AuthCubit(this._authService) : super(const AuthInitial());

  /// Initializes the cubit and listens for auth state changes.
  void init() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    });

    // Check if user is already authenticated
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      emit(Authenticated(currentUser));
    } else {
      emit(const Unauthenticated());
    }
  }

  /// Signs in with Google.
  Future<void> loginWithGoogle() async {
    try {
      emit(const AuthLoading());
      final user = await _authService.loginWithGoogle();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Signs in with Apple.
  Future<void> loginWithApple() async {
    try {
      emit(const AuthLoading());
      final user = await _authService.loginWithApple();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Signs in with biometrics.
  Future<void> loginWithBiometrics() async {
    try {
      emit(const AuthLoading());
      final user = await _authService.loginWithBiometrics();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Signs out the current user.
  Future<void> logout() async {
    try {
      await _authService.logout();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Checks if biometric authentication is available.
  Future<bool> isBiometricAvailable() async {
    return _authService.isBiometricAvailable();
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
