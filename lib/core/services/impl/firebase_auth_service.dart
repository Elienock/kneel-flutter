import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quick_church/core/services/interfaces/i_auth_service.dart';
import 'package:quick_church/core/services/interfaces/i_biometric_service.dart';
import 'package:quick_church/core/services/interfaces/i_profile_service.dart';
import 'package:quick_church/core/utils/kneel_logger.dart';
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
        KneelLogger.authStateChanged(null);
        return null;
      }
      KneelLogger.authStateChanged(firebaseUser.uid);
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
      KneelLogger.error('FirebaseAuthService.loginWithGoogle', e);
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
      KneelLogger.log('Sending verification code to: $phoneNumber');

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (firebase.PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          KneelLogger.log('Phone auto-verification completed');
          try {
            final userCredential = await _firebaseAuth.signInWithCredential(credential);
            final firebaseUser = userCredential.user;
            if (firebaseUser != null) {
              await _syncProfileToSupabase(firebaseUser, 'phone');
              await _saveSessionInfo(firebaseUser.uid);
              onAutoVerified?.call(_mapFirebaseUser(firebaseUser));
            }
          } catch (e) {
            KneelLogger.error('Auto-verification sign-in failed', e);
          }
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          KneelLogger.error('Phone verification failed', e.message);
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
          KneelLogger.log('Verification code sent. ID: $verificationId');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          KneelLogger.log('Auto-retrieval timeout for: $verificationId');
        },
      );
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.sendPhoneVerificationCode', e);
      onVerificationFailed(e.toString());
    }
  }

  @override
  Future<User> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      KneelLogger.log('Verifying phone code...');

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

      KneelLogger.log('Phone authentication successful');
      return _mapFirebaseUser(firebaseUser);
    } on firebase.FirebaseAuthException catch (e) {
      KneelLogger.error('FirebaseAuthService.verifyPhoneCode', e.message);
      if (e.code == 'invalid-verification-code') {
        throw Exception('Invalid verification code. Please try again.');
      } else if (e.code == 'session-expired') {
        throw Exception('Verification code expired. Please request a new code.');
      }
      rethrow;
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.verifyPhoneCode', e);
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
      KneelLogger.log('Registering with email: $email');

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
      KneelLogger.log('Verification email sent to: $email');

      // Sync profile to Supabase
      await _syncProfileToSupabase(
        _firebaseAuth.currentUser!,
        'email',
      );

      // Save session info
      await _saveSessionInfo(firebaseUser.uid);

      return _mapFirebaseUser(_firebaseAuth.currentUser!);
    } on firebase.FirebaseAuthException catch (e) {
      KneelLogger.error('FirebaseAuthService.registerWithEmail', e.message);
      if (e.code == 'weak-password') {
        throw Exception('Password is too weak. Please use a stronger password.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists with this email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address.');
      }
      rethrow;
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.registerWithEmail', e);
      rethrow;
    }
  }

  @override
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      KneelLogger.log('Signing in with email: $email');

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

      KneelLogger.log('Email login successful');
      return _mapFirebaseUser(firebaseUser);
    } on firebase.FirebaseAuthException catch (e) {
      KneelLogger.error('FirebaseAuthService.loginWithEmail', e.message);
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
      KneelLogger.error('FirebaseAuthService.loginWithEmail', e);
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      KneelLogger.log('Sending password reset email to: $email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      KneelLogger.log('Password reset email sent');
    } on firebase.FirebaseAuthException catch (e) {
      KneelLogger.error('FirebaseAuthService.sendPasswordResetEmail', e.message);
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address.');
      }
      rethrow;
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.sendPasswordResetEmail', e);
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
      KneelLogger.log('Verification email sent');
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.sendEmailVerification', e);
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
      KneelLogger.error('FirebaseAuthService.reloadUser', e);
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
        KneelLogger.log('Biometric auth: Using existing Firebase session');
        return _mapFirebaseUser(currentUser);
      }

      // No existing session
      throw Exception('Session expired. Please sign in again.');
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.loginWithBiometrics', e);
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
      KneelLogger.log('User signed out', context: 'Auth');
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.logout', e);
      rethrow;
    }
  }

  @override
  @Deprecated('Use forceLogoutAndClearAllData instead')
  Future<void> forceGlobalLogout() async {
    await forceLogoutAndClearAllData();
  }

  @override
  Future<bool> forceLogoutAndClearAllData() async {
    KneelLogger.log('=== SELF-HEALING SESSION RESET ===', context: 'Auth');
    KneelLogger.log('Clearing ALL session data...', context: 'Auth');

    bool success = true;

    // Step 1: Disconnect Google Sign-In (fully clears cached account)
    try {
      await _googleSignIn.disconnect();
      KneelLogger.log('[1/3] Google Sign-In disconnected', context: 'Auth');
    } catch (e) {
      KneelLogger.warn('[1/3] Google disconnect failed (may not be signed in): $e', context: 'Auth');
      // Not a critical failure - user might not have used Google
    }

    // Step 2: Sign out from Firebase Auth
    try {
      await _firebaseAuth.signOut();
      KneelLogger.log('[2/3] Firebase Auth signed out', context: 'Auth');
    } catch (e) {
      KneelLogger.error('[2/3] Firebase signOut failed', e);
      success = false;
    }

    // Step 3: Clear ALL SharedPreferences (nuclear option)
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear specific session keys
      await prefs.remove(_lastUserIdKey);
      await prefs.remove(_hasSessionKey);
      // Reset session flag explicitly
      await prefs.setBool(_hasSessionKey, false);
      // Optionally clear ALL prefs for complete reset (uncomment if needed)
      // await prefs.clear();
      KneelLogger.log('[3/3] SharedPreferences cleared', context: 'Auth');
    } catch (e) {
      KneelLogger.error('[3/3] SharedPreferences clear failed', e);
      success = false;
    }

    KneelLogger.log('=== SESSION RESET ${success ? 'COMPLETE' : 'PARTIAL'} ===', context: 'Auth');
    return success;
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
  ///
  /// IDENTITY SYNC: If user already exists in Supabase, MERGE the data
  /// instead of overwriting their existing Bio/Location with defaults.
  Future<void> _syncProfileToSupabase(firebase.User firebaseUser, String provider) async {
    try {
      // First, check if user already has a profile
      final existingProfile = await _profileService.getProfile(firebaseUser.uid);

      if (existingProfile != null) {
        // MERGE: Preserve existing bio, location, and other user data
        KneelLogger.log('Merging with existing Supabase profile', context: 'Auth');
        await _profileService.upsertProfile(
          uid: firebaseUser.uid,
          email: firebaseUser.email?.isNotEmpty == true
              ? firebaseUser.email!
              : existingProfile.email,
          displayName: firebaseUser.displayName ?? existingProfile.displayName,
          photoUrl: firebaseUser.photoURL ?? existingProfile.photoUrl,
          provider: provider,
          phoneNumber: firebaseUser.phoneNumber ?? existingProfile.phoneNumber,
          // PRESERVE existing user-entered data
          bio: existingProfile.bio,
          locationCity: existingProfile.locationCity,
          googlePlaceId: existingProfile.googlePlaceId,
          emailVerified: firebaseUser.emailVerified || existingProfile.emailVerified,
        );
      } else {
        // New user - create profile with Firebase data
        KneelLogger.log('Creating new Supabase profile', context: 'Auth');
        await _profileService.upsertProfile(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          provider: provider,
          phoneNumber: firebaseUser.phoneNumber,
          emailVerified: firebaseUser.emailVerified,
        );
      }
    } catch (e) {
      // Log but don't fail auth if Supabase sync fails
      KneelLogger.error('Failed to sync profile to Supabase', e);
    }
  }

  /// Saves session info for biometric re-authentication.
  Future<void> _saveSessionInfo(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, uid);
    await prefs.setBool(_hasSessionKey, true);
  }
}
