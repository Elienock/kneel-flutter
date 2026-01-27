import 'package:quick_church/features/auth/domain/entities/user.dart';

/// Abstract interface for authentication services.
/// Allows for easy swapping between mock and real implementations (e.g., Firebase).
abstract class IAuthService {
  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges;

  /// Gets the currently authenticated user, or null if not authenticated.
  User? getCurrentUser();

  /// Signs in with Google OAuth.
  /// Returns the authenticated user on success.
  Future<User> loginWithGoogle();

  /// Signs in with Apple OAuth.
  /// Returns the authenticated user on success.
  Future<User> loginWithApple();

  /// Signs in using device biometrics (fingerprint/face).
  /// Returns the authenticated user on success.
  Future<User> loginWithBiometrics();

  /// Signs out the current user.
  Future<void> logout();

  /// Checks if biometric authentication is available on this device.
  Future<bool> isBiometricAvailable();
}
