import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quick_church/core/services/interfaces/i_auth_service.dart';
import 'package:quick_church/core/services/interfaces/i_biometric_service.dart';
import 'package:quick_church/core/services/interfaces/i_profile_service.dart';
import 'package:quick_church/core/utils/debug_logger.dart';
import 'package:quick_church/features/auth/domain/entities/user.dart';

/// Implementation of [IAuthService] using Firebase Authentication.
@LazySingleton(as: IAuthService)
class FirebaseAuthService implements IAuthService {
  final firebase.FirebaseAuth _firebaseAuth = firebase.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final IBiometricService _biometricService;
  final IProfileService _profileService;

  static const _lastUserIdKey = 'last_authenticated_user_id';
  static const _hasSessionKey = 'has_previous_session';

  FirebaseAuthService(this._biometricService, this._profileService);

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        DebugLogger.authStateChanged(null);
        return null;
      }
      DebugLogger.authStateChanged(firebaseUser.uid);
      return _mapFirebaseUser(firebaseUser);
    });
  }

  @override
  User? getCurrentUser() {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUser(firebaseUser);
  }

  // ===== Google Authentication =====

  @override
  Future<User> loginWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed');
      }

      // Sync profile to Supabase
      await _syncProfileToSupabase(firebaseUser, 'google');

      // Save session info for biometric re-authentication
      await _saveSessionInfo(firebaseUser.uid);

      return _mapFirebaseUser(firebaseUser);
    } catch (e) {
      DebugLogger.error('FirebaseAuthService.loginWithGoogle', e);
      rethrow;
    }
  }

  // ===== Phone Authentication =====

  @override
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
    Function(User user)? onAutoVerified,
  }) async {
    try {
      DebugLogger.log('Sending verification code to: $phoneNumber');

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (firebase.PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          DebugLogger.log('Phone auto-verification completed');
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(credential);
            final firebaseUser = userCredential.user;
            if (firebaseUser != null) {
              await _syncProfileToSupabase(firebaseUser, 'phone');
              await _saveSessionInfo(firebaseUser.uid);
              onAutoVerified?.call(_mapFirebaseUser(firebaseUser));
            }
          } catch (e) {
            DebugLogger.error('Auto-verification sign-in failed', e);
          }
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          DebugLogger.error('Phone verification failed', e.message);
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later.';
          } else if (e.message != null) {
            errorMessage = e.message!;
          }
          onVerificationFailed(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          DebugLogger.log('Verification code sent. ID: $verificationId');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          DebugLogger.log('Auto-retrieval timeout for: $verificationId');
        },
      );
    } catch (e) {
      DebugLogger.error('FirebaseAuthService.sendPhoneVerificationCode', e);
      onVerificationFailed(e.toString());
    }
  }

  @override
  Future<User> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      DebugLogger.log('Verifying phone code...');

      // Create credential with the verification ID and SMS code
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign in with the credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Phone authentication failed');
      }

      // Sync profile to Supabase
      await _syncProfileToSupabase(firebaseUser, 'phone');

      // Save session info for biometric re-authentication
      await _saveSessionInfo(firebaseUser.uid);

      DebugLogger.log('Phone authentication successful');
      return _mapFirebaseUser(firebaseUser);
    } on firebase.FirebaseAuthException catch (e) {
      DebugLogger.error('FirebaseAuthService.verifyPhoneCode', e.message);
      if (e.code == 'invalid-verification-code') {
        throw Exception('Invalid verification code. Please try again.');
      } else if (e.code == 'session-expired') {
        throw Exception('Verification code expired. Please request a new code.');
      }
      rethrow;
    } catch (e) {
      DebugLogger.error('FirebaseAuthService.verifyPhoneCode', e);
      rethrow;
    }
  }

  // ===== Email/Password Authentication =====

  @override
  Future<User> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      DebugLogger.log('Registering with email: $email');

      // Create user with email and password
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Registration failed');
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await firebaseUser.updateDisplayName(displayName);
        await firebaseUser.reload();
      }

      // Send email verification
      await firebaseUser.sendEmailVerification();
      DebugLogger.log('Verification email sent to: $email');

      // Sync profile to Supabase
      await _syncProfileToSupabase(
        _firebaseAuth.currentUser!,
        'email',
      );

      // Save session info
      await _saveSessionInfo(firebaseUser.uid);

      return _mapFirebaseUser(_firebaseAuth.currentUser!);
    } on firebase.FirebaseAuthException catch (e) {
      DebugLogger.error('FirebaseAuthService.registerWithEmail', e.message);
      if (e.code == 'weak-password') {
        throw Exception('Password is too weak. Please use a stronger password.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists with this email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address.');
      }
      rethrow;
    } catch (e) {
      DebugLogger.error('FirebaseAuthService.registerWithEmail', e);
      rethrow;
    }
  }

  @override
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      DebugLogger.log('Signing in with email: $email');

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Login failed');
      }

      // Sync profile to Supabase
      await _syncProfileToSupabase(firebaseUser, 'email');

      // Save session info
      await _saveSessionInfo(firebaseUser.uid);

      DebugLogger.log('Email login successful');
      return _mapFirebaseUser(firebaseUser);
    } on firebase.FirebaseAuthException catch (e) {
      DebugLogger.error('FirebaseAuthService.loginWithEmail', e.message);
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled.');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Invalid email or password.');
      }
      rethrow;
    } catch (e) {
      DebugLogger.error('FirebaseAuthService.loginWithEmail', e);
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      DebugLogger.log('Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      DebugLogger.log('Password reset email sent');
    } on firebase.FirebaseAuthException catch (e) {
      DebugLogger.error('FirebaseAuthService.sendPasswordResetEmail', e.message);
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address.');
      }
      rethrow;
    } catch (e) {
      DebugLogger.error('FirebaseAuthService.sendPasswordResetEmail', e);
      rethrow;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }
      if (user.emailVerified) {
        throw Exception('Email is already verified');
      }
      await user.sendEmailVerification();
      DebugLogger.log('Verification email sent');
    } catch (e) {
      DebugLogger.error('FirebaseAuthService.sendEmailVerification', e);
      rethrow;
    }
  }

  @override
  Future<User?> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      await user.reload();
      return _mapFirebaseUser(_firebaseAuth.currentUser!);
    } catch (e) {
      DebugLogger.error('FirebaseAuthService.reloadUser', e);
      return null;
    }
  }

  // ===== Biometric Authentication =====

  @override
  Future<User> loginWithBiometrics() async {
    try {
      // First, verify biometrics
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to sign in to Kneel',
      );

      if (!authenticated) {
        throw Exception('Biometric authentication failed');
      }

      // Check if there's an existing Firebase session
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        DebugLogger.log('Biometric auth: Using existing Firebase session');
        return _mapFirebaseUser(currentUser);
      }

      // No existing session
      throw Exception('Session expired. Please sign in again.');
    } catch (e) {
      DebugLogger.error('FirebaseAuthService.loginWithBiometrics', e);
      rethrow;
    }
  }

  @override
  Future<bool> isBiometricAvailable() async {
    return _biometricService.isAvailable();
  }

  @override
  Future<bool> hasPreviousSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSessionKey) ?? false;
  }

  // ===== Session Management =====

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      DebugLogger.log('User signed out');
    } catch (e) {
      DebugLogger.error('FirebaseAuthService.logout', e);
      rethrow;
    }
  }

  // ===== Private Helpers =====

  /// Maps a Firebase user to our domain User entity.
  User _mapFirebaseUser(firebase.User firebaseUser) {
    // Determine the auth provider
    AuthProvider provider = AuthProvider.email;
    if (firebaseUser.providerData.isNotEmpty) {
      final providerId = firebaseUser.providerData.first.providerId;
      if (providerId.contains('google')) {
        provider = AuthProvider.google;
      } else if (providerId.contains('phone')) {
        provider = AuthProvider.phone;
      } else if (providerId.contains('password')) {
        provider = AuthProvider.email;
      }
    }

    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'Prayer Warrior',
      photoUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      provider: provider,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      isEmailVerified: firebaseUser.emailVerified,
    );
  }

  /// Syncs the Firebase user profile to Supabase.
  Future<void> _syncProfileToSupabase(firebase.User firebaseUser, String provider) async {
    try {
      await _profileService.upsertProfile(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        provider: provider,
        phoneNumber: firebaseUser.phoneNumber,
      );
    } catch (e) {
      // Log but don't fail auth if Supabase sync fails
      DebugLogger.error('Failed to sync profile to Supabase', e);
    }
  }

  /// Saves session info for biometric re-authentication.
  Future<void> _saveSessionInfo(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, uid);
    await prefs.setBool(_hasSessionKey, true);
  }
}
