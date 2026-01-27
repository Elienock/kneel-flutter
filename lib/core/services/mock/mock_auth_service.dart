import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:quick_church/core/services/interfaces/i_auth_service.dart';
import 'package:quick_church/features/auth/domain/entities/user.dart';

/// Mock implementation of [IAuthService] for development and testing.
/// Simulates network delays and returns mock user data.
@LazySingleton(as: IAuthService)
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
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<User> loginWithApple() async {
    await Future.delayed(_mockDelay);

    _currentUser = User(
      id: 'apple_user_456',
      email: 'user@icloud.com',
      displayName: 'Faithful One',
      photoUrl: null,
      provider: AuthProvider.apple,
      createdAt: DateTime.now(),
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<User> loginWithBiometrics() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real implementation, this would verify biometrics first
    // and then restore the previously authenticated user
    _currentUser = User(
      id: 'biometric_user_789',
      email: 'local@device.com',
      displayName: 'Local User',
      photoUrl: null,
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
  Future<bool> isBiometricAvailable() async {
    // Mock: always return true for testing
    // Real implementation would check device capabilities
    return true;
  }

  void dispose() {
    _authStateController.close();
  }
}
