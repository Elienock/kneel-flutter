import 'package:quick_church/features/auth/domain/entities/user.dart';

/// Abstract interface for authentication services.
/// Allows for easy swapping between mock and real implementations (e.g., Firebase).
abstract class IAuthService {
  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges;

  /// Gets the currently authenticated user, or null if not authenticated.
  User? getCurrentUser();

  // ===== Google Authentication =====

  /// Signs in with Google OAuth.
  /// Returns the authenticated user on success.
  Future<User> loginWithGoogle();

  // ===== Phone Authentication =====

  /// Initiates phone number verification.
  /// Sends an SMS with OTP to the provided phone number.
  /// [phoneNumber] should include country code (e.g., +27123456789).
  /// [onCodeSent] is called when the SMS is sent, providing the verificationId.
  /// [onVerificationFailed] is called if verification fails.
  /// [onAutoVerified] is called if auto-verification succeeds (Android only).
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
    Function(User user)? onAutoVerified,
  });

  /// Verifies the OTP code and signs in the user.
  /// [verificationId] is provided by [sendPhoneVerificationCode].
  /// [smsCode] is the 6-digit code entered by the user.
  Future<User> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  // ===== Email/Password Authentication =====

  /// Creates a new account with email and password.
  /// Sends a verification email after registration.
  Future<User> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs in with email and password.
  Future<User> loginWithEmail({
    required String email,
    required String password,
  });

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Sends an email verification to the current user.
  Future<void> sendEmailVerification();

  /// Reloads the current user to check for email verification status.
  Future<User?> reloadUser();

  // ===== Biometric Authentication =====

  /// Signs in using device biometrics (fingerprint/face).
  /// Returns the authenticated user on success.
  Future<User> loginWithBiometrics();

  /// Checks if biometric authentication is available on this device.
  Future<bool> isBiometricAvailable();

  /// Checks if user has previously signed in (for biometric re-auth).
  Future<bool> hasPreviousSession();

  // ===== Session Management =====

  /// Signs out the current user.
  Future<void> logout();

  /// Force global logout - clears ALL session data.
  /// Use when user is deleted from backend or session is corrupted.
  /// 1. Signs out from Firebase
  /// 2. Clears SharedPreferences session flags
  /// 3. Clears Google Sign-In cache
  @Deprecated('Use forceLogoutAndClearAllData instead')
  Future<void> forceGlobalLogout();

  /// Self-Healing Session Reset: Nuclear option for zombie sessions.
  ///
  /// Clears ALL persistent data to allow a fresh start:
  /// 1. Signs out from Firebase Auth
  /// 2. Disconnects Google Sign-In (clears cached account)
  /// 3. Clears ALL SharedPreferences (session flags, user prefs)
  /// 4. Returns true if successful, false if any step failed
  ///
  /// Use cases:
  /// - User deleted from backend but local session persists
  /// - PostgrestException with 'User Not Found' or 'Unauthorized'
  /// - Debug reset button in development
  Future<bool> forceLogoutAndClearAllData();
}
