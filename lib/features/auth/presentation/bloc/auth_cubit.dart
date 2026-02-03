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

  // ===== Google Authentication =====

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

  // ===== Phone Authentication =====

  /// Sends phone verification code.
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
  }) async {
    try {
      emit(const AuthLoading());
      await _authService.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          emit(const PhoneCodeSent());
          onCodeSent(verificationId);
        },
        onVerificationFailed: (error) {
          emit(AuthError(error));
          emit(const Unauthenticated());
          onVerificationFailed(error);
        },
        onAutoVerified: (user) {
          emit(Authenticated(user));
        },
      );
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Verifies phone code and signs in.
  Future<void> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      emit(const AuthLoading());
      final user = await _authService.verifyPhoneCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const PhoneCodeSent()); // Stay on OTP screen
    }
  }

  // ===== Email/Password Authentication =====

  /// Registers with email and password.
  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      emit(const AuthLoading());
      final user = await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Signs in with email and password.
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      emit(const AuthLoading());
      final user = await _authService.loginWithEmail(
        email: email,
        password: password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
    }
  }

  /// Sends password reset email.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      emit(const AuthLoading());
      await _authService.sendPasswordResetEmail(email);
      emit(const Unauthenticated());
      return true;
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const Unauthenticated());
      return false;
    }
  }

  /// Sends email verification.
  Future<bool> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  /// Reloads user to check email verification status.
  Future<void> reloadUser() async {
    final user = await _authService.reloadUser();
    if (user != null) {
      emit(Authenticated(user));
    }
  }

  // ===== Biometric Authentication =====

  /// Signs in with biometrics using stored credentials.
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

  /// Checks if biometric authentication is available on device.
  Future<bool> isBiometricAvailable() async {
    return _authService.isBiometricAvailable();
  }

  /// Checks if biometric login is enabled with stored credentials.
  /// Use this to decide whether to show the biometric button on Start Page.
  Future<bool> isBiometricLoginEnabled() async {
    return _authService.isBiometricLoginEnabled();
  }

  /// Checks if user has a previous session (legacy check).
  Future<bool> hasPreviousSession() async {
    return _authService.hasPreviousSession();
  }

  /// Enables biometric re-authentication for the current user.
  /// Shows biometric prompt to verify identity before storing credentials.
  /// Returns true if enabled successfully.
  Future<bool> enableBiometricLogin() async {
    return _authService.enableBiometricLogin();
  }

  /// Disables biometric re-authentication.
  /// Clears stored credentials from secure storage.
  Future<void> disableBiometricLogin() async {
    return _authService.disableBiometricLogin();
  }

  // ===== Phone Linking =====

  /// Links a phone number to the current user's account.
  Future<void> linkPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
    Function()? onLinkSuccess,
  }) async {
    try {
      emit(const AuthLoading());
      await _authService.linkPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          emit(const PhoneCodeSent());
          onCodeSent(verificationId);
        },
        onVerificationFailed: (error) {
          emit(AuthError(error));
          onVerificationFailed(error);
        },
        onLinkSuccess: onLinkSuccess,
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Verifies OTP and links phone to current account.
  Future<void> verifyAndLinkPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      emit(const AuthLoading());
      await _authService.verifyAndLinkPhone(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      // Refresh user state
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const PhoneCodeSent()); // Stay on OTP screen
    }
  }

  // ===== Password Management =====

  /// Updates the current user's password.
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      emit(const AuthLoading());
      await _authService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      // Refresh user state
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        emit(Authenticated(currentUser));
      }
      return true;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  // ===== Session Management =====

  /// Signs out the current user.
  Future<void> logout() async {
    try {
      await _authService.logout();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
