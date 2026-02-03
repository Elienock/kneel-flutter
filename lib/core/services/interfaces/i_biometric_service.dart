/// Abstract interface for biometric authentication services.
///
/// Handles device biometric authentication (fingerprint/face ID) and
/// secure storage of authentication tokens for one-touch re-login.
abstract class IBiometricService {
  /// Checks if biometric authentication is available on this device.
  Future<bool> isAvailable();

  /// Checks if the device has enrolled biometrics (fingerprint/face).
  Future<bool> hasEnrolledBiometrics();

  /// Authenticates the user using device biometrics.
  /// Returns true if authentication was successful.
  Future<bool> authenticate({String reason = 'Please authenticate to continue'});

  // =========================================================================
  // BIOMETRIC RE-AUTHENTICATION (One-Touch Login)
  // =========================================================================

  /// Checks if the user has enabled biometric re-authentication.
  /// Returns true if biometrics are enabled AND a valid token is stored.
  Future<bool> isBiometricLoginEnabled();

  /// Enables biometric re-authentication by storing the refresh token securely.
  ///
  /// [refreshToken] - The Firebase refresh token to store.
  /// [userId] - The user's Firebase UID for validation.
  ///
  /// Returns true if the token was stored successfully.
  Future<bool> enableBiometricLogin({
    required String refreshToken,
    required String userId,
  });

  /// Disables biometric re-authentication by deleting all stored credentials.
  /// Call this when the user toggles off biometrics in settings.
  Future<void> disableBiometricLogin();

  /// Retrieves the stored refresh token after successful biometric authentication.
  /// Returns null if no token is stored or if biometrics are disabled.
  Future<String?> getStoredRefreshToken();

  /// Retrieves the stored user ID for validation.
  Future<String?> getStoredUserId();

  /// Clears all stored biometric credentials.
  /// Call this on logout or account deletion.
  Future<void> clearAllCredentials();
}
