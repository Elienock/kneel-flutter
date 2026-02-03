import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:quick_church/core/services/interfaces/i_biometric_service.dart';
import 'package:quick_church/core/utils/kneel_logger.dart';

/// Implementation of [IBiometricService] using local_auth and flutter_secure_storage.
///
/// Handles:
/// - Device biometric authentication (fingerprint/face ID)
/// - Secure storage of refresh tokens for one-touch re-login
/// - Biometric preference management
@LazySingleton(as: IBiometricService)
class BiometricService implements IBiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Secure storage with Android-specific options for enhanced security
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'kneel_biometric_prefs',
      preferencesKeyPrefix: 'kneel_',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'KneelBiometricAuth',
    ),
  );

  // Storage keys
  static const _keyRefreshToken = 'biometric_refresh_token';
  static const _keyUserId = 'biometric_user_id';
  static const _keyBiometricEnabled = 'biometric_enabled';

  // =========================================================================
  // DEVICE BIOMETRIC AUTHENTICATION
  // =========================================================================

  @override
  Future<bool> isAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      KneelLogger.error('BiometricService.isAvailable', e);
      return false;
    }
  }

  @override
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      KneelLogger.error('BiometricService.hasEnrolledBiometrics', e);
      return false;
    }
  }

  @override
  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    try {
      final isAvail = await isAvailable();
      if (!isAvail) {
        KneelLogger.log('Biometric authentication not available');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );

      KneelLogger.biometric('Authentication result: $authenticated');
      return authenticated;
    } catch (e) {
      KneelLogger.error('BiometricService.authenticate', e);
      return false;
    }
  }

  // =========================================================================
  // BIOMETRIC RE-AUTHENTICATION (One-Touch Login)
  // =========================================================================

  @override
  Future<bool> isBiometricLoginEnabled() async {
    try {
      // Check if biometrics are available on device
      final available = await isAvailable();
      if (!available) return false;

      // Check if user has enabled biometric login
      final enabled = await _secureStorage.read(key: _keyBiometricEnabled);
      if (enabled != 'true') return false;

      // Check if we have a stored token
      final token = await _secureStorage.read(key: _keyRefreshToken);
      final hasToken = token != null && token.isNotEmpty;

      KneelLogger.biometric('Biometric login enabled: $hasToken');
      return hasToken;
    } catch (e) {
      KneelLogger.error('BiometricService.isBiometricLoginEnabled', e);
      return false;
    }
  }

  @override
  Future<bool> enableBiometricLogin({
    required String refreshToken,
    required String userId,
  }) async {
    try {
      KneelLogger.biometric('Enabling biometric login for user: $userId');

      // First verify biometrics work on this device
      final authenticated = await authenticate(
        reason: 'Verify your identity to enable one-touch login',
      );

      if (!authenticated) {
        KneelLogger.biometric('Biometric verification failed - not enabling');
        return false;
      }

      // Store credentials securely
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
      await _secureStorage.write(key: _keyUserId, value: userId);
      await _secureStorage.write(key: _keyBiometricEnabled, value: 'true');

      KneelLogger.biometric('Biometric login enabled successfully');
      return true;
    } catch (e) {
      KneelLogger.error('BiometricService.enableBiometricLogin', e);
      // Clean up on failure
      await clearAllCredentials();
      return false;
    }
  }

  @override
  Future<void> disableBiometricLogin() async {
    try {
      KneelLogger.biometric('Disabling biometric login');
      await clearAllCredentials();
      KneelLogger.biometric('Biometric login disabled');
    } catch (e) {
      KneelLogger.error('BiometricService.disableBiometricLogin', e);
    }
  }

  @override
  Future<String?> getStoredRefreshToken() async {
    try {
      final enabled = await _secureStorage.read(key: _keyBiometricEnabled);
      if (enabled != 'true') return null;

      return await _secureStorage.read(key: _keyRefreshToken);
    } catch (e) {
      KneelLogger.error('BiometricService.getStoredRefreshToken', e);
      return null;
    }
  }

  @override
  Future<String?> getStoredUserId() async {
    try {
      return await _secureStorage.read(key: _keyUserId);
    } catch (e) {
      KneelLogger.error('BiometricService.getStoredUserId', e);
      return null;
    }
  }

  @override
  Future<void> clearAllCredentials() async {
    try {
      await _secureStorage.delete(key: _keyRefreshToken);
      await _secureStorage.delete(key: _keyUserId);
      await _secureStorage.delete(key: _keyBiometricEnabled);
      KneelLogger.biometric('All biometric credentials cleared');
    } catch (e) {
      KneelLogger.error('BiometricService.clearAllCredentials', e);
    }
  }
}
