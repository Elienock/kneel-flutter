import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:quick_church/core/services/interfaces/i_biometric_service.dart';
import 'package:quick_church/core/utils/debug_logger.dart';

/// Implementation of [IBiometricService] using local_auth package.
@LazySingleton(as: IBiometricService)
class BiometricService implements IBiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      DebugLogger.error('BiometricService.isAvailable', e);
      return false;
    }
  }

  @override
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      DebugLogger.error('BiometricService.hasEnrolledBiometrics', e);
      return false;
    }
  }

  @override
  Future<bool> authenticate({String reason = 'Please authenticate to continue'}) async {
    try {
      final isAvail = await isAvailable();
      if (!isAvail) {
        DebugLogger.log('Biometric authentication not available');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );

      DebugLogger.log('Biometric authentication result: $authenticated');
      return authenticated;
    } catch (e) {
      DebugLogger.error('BiometricService.authenticate', e);
      return false;
    }
  }
}
