/// Abstract interface for biometric authentication services.
abstract class IBiometricService {
  /// Checks if biometric authentication is available on this device.
  Future<bool> isAvailable();

  /// Checks if the device has enrolled biometrics (fingerprint/face).
  Future<bool> hasEnrolledBiometrics();

  /// Authenticates the user using device biometrics.
  /// Returns true if authentication was successful.
  Future<bool> authenticate({String reason = 'Please authenticate to continue'});
}
