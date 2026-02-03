import 'dart:async';
import 'package:quick_church/core/services/interfaces/i_auth_service.dart';
import 'package:quick_church/features/auth/domain/entities/user.dart';

/// Mock implementation of [IAuthService] for development and testing.
/// Simulates network delays and returns mock user data.
/// NOTE: Not registered with injectable - use FirebaseAuthService in production.
class MockAuthService implements IAuthService {
  final _authStateController = StreamController<User?>.broadcast();
  User? _currentUser;

  static const _mockDelay = Duration(milliseconds: 1500);

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  User? getCurrentUser() => _currentUser;

  @override
  Future<User> loginWithGoogle() async {
    await Future.delayed(_mockDelay);

    _currentUser = User(
      id: 'google_user_123',
      email: 'user@gmail.com',
      displayName: 'Prayer Warrior',
      photoUrl: 'https://ui-avatars.com/api/?name=Prayer+Warrior&background=673AB7&color=fff',
      provider: AuthProvider.google,
      createdAt: DateTime.now(),
      isEmailVerified: true,
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
    Function(User user)? onAutoVerified,
  }) async {
    await Future.delayed(_mockDelay);
    onCodeSent('mock_verification_id_123');
  }

  @override
  Future<User> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future.delayed(_mockDelay);

    if (smsCode != '123456') {
      throw Exception('Invalid verification code');
    }

    _currentUser = User(
      id: 'phone_user_456',
      email: '',
      displayName: 'Prayer Warrior',
      phoneNumber: '+27123456789',
      provider: AuthProvider.phone,
      createdAt: DateTime.now(),
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<User> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await Future.delayed(_mockDelay);

    _currentUser = User(
      id: 'email_user_789',
      email: email,
      displayName: displayName ?? 'Prayer Warrior',
      provider: AuthProvider.email,
      createdAt: DateTime.now(),
      isEmailVerified: false,
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(_mockDelay);

    _currentUser = User(
      id: 'email_user_789',
      email: email,
      displayName: 'Prayer Warrior',
      provider: AuthProvider.email,
      createdAt: DateTime.now(),
      isEmailVerified: true,
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(_mockDelay);
    // Mock: just complete successfully
  }

  @override
  Future<void> sendEmailVerification() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: just complete successfully
  }

  @override
  Future<User?> reloadUser() async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isEmailVerified: true);
      _authStateController.add(_currentUser);
    }
    return _currentUser;
  }

  @override
  Future<User> loginWithBiometrics() async {
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = User(
      id: 'biometric_user_789',
      email: 'local@device.com',
      displayName: 'Local User',
      provider: AuthProvider.biometric,
      createdAt: DateTime.now(),
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  @Deprecated('Use forceLogoutAndClearAllData instead')
  Future<void> forceGlobalLogout() async {
    await forceLogoutAndClearAllData();
  }

  @override
  Future<bool> forceLogoutAndClearAllData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authStateController.add(null);
    return true;
  }

  @override
  Future<bool> isBiometricAvailable() async {
    return true;
  }

  @override
  Future<bool> isBiometricLoginEnabled() async {
    return false; // Mock: biometric login not enabled
  }

  @override
  Future<bool> hasPreviousSession() async {
    return true;
  }

  @override
  Future<String?> getRefreshToken() async {
    return 'mock_refresh_token';
  }

  @override
  Future<bool> enableBiometricLogin() async {
    return true; // Mock: always succeeds
  }

  @override
  Future<void> disableBiometricLogin() async {
    // Mock: no-op
  }

  @override
  Future<void> linkPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
    Function()? onLinkSuccess,
  }) async {
    await Future.delayed(_mockDelay);
    onCodeSent('mock_link_verification_id');
  }

  @override
  Future<void> verifyAndLinkPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    await Future.delayed(_mockDelay);
    if (smsCode != '123456') {
      throw Exception('Invalid verification code');
    }
    // Mock: Update current user with phone
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(phoneNumber: '+27123456789');
      _authStateController.add(_currentUser);
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(_mockDelay);
    if (currentPassword != 'password123') {
      throw Exception('Current password is incorrect');
    }
    // Mock: Password updated successfully
  }

  void dispose() {
    _authStateController.close();
  }
}
