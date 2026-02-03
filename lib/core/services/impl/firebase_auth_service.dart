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

  /// Track if auto-verification has completed to prevent duplicate submissions
  bool _autoVerificationCompleted = false;

  @override
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
    Function(User user)? onAutoVerified,
  }) async {
    try {
      // Reset auto-verification flag
      _autoVerificationCompleted = false;

      KneelLogger.log('📱 Sending verification code to: $phoneNumber', context: 'PhoneAuth');

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 120), // Increased timeout
        verificationCompleted: (firebase.PhoneAuthCredential credential) async {
          // Auto-verification (Android only) - SMS was auto-read
          KneelLogger.log('✅ AUTO-VERIFICATION COMPLETED (SMS auto-read)', context: 'PhoneAuth');
          _autoVerificationCompleted = true;

          try {
            final userCredential = await _firebaseAuth.signInWithCredential(credential);
            final firebaseUser = userCredential.user;
            if (firebaseUser != null) {
              await _syncProfileToSupabase(firebaseUser, 'phone');
              await _saveSessionInfo(firebaseUser.uid);
              KneelLogger.log('✅ Auto-verification sign-in successful', context: 'PhoneAuth');
              onAutoVerified?.call(_mapFirebaseUser(firebaseUser));
            }
          } catch (e) {
            KneelLogger.error('PhoneAuth: Auto-verification sign-in failed', e);
            _autoVerificationCompleted = false; // Allow manual retry
          }
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          KneelLogger.error('PhoneAuth: Verification failed - ${e.code}', e.message);
          String errorMessage = 'Verification failed';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many attempts. Please wait a few minutes.';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'SMS quota exceeded. Please try again later.';
          } else if (e.message != null) {
            errorMessage = e.message!;
          }
          onVerificationFailed(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          KneelLogger.log('📨 SMS Code sent. VerificationID: ${verificationId.substring(0, 20)}...', context: 'PhoneAuth');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          KneelLogger.log('⏱️ Auto-retrieval timeout (normal)', context: 'PhoneAuth');
          // This is normal - just means SMS wasn't auto-read
        },
      );
    } catch (e) {
      KneelLogger.error('PhoneAuth: sendPhoneVerificationCode failed', e);
      onVerificationFailed(e.toString());
    }
  }

  /// Check if auto-verification has already completed
  bool get isAutoVerificationCompleted => _autoVerificationCompleted;

  @override
  Future<User> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    // Guard: Don't verify if auto-verification already succeeded
    if (_autoVerificationCompleted) {
      KneelLogger.warn('PhoneAuth: Skipping manual verification - auto-verification already completed', context: 'PhoneAuth');
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        return _mapFirebaseUser(currentUser);
      }
      throw Exception('Auto-verification completed but no user found');
    }

    try {
      KneelLogger.log('🔐 Manual OTP verification starting...', context: 'PhoneAuth');
      KneelLogger.log('   VerificationID: ${verificationId.substring(0, 20)}...', context: 'PhoneAuth');
      KneelLogger.log('   SMS Code: $smsCode', context: 'PhoneAuth');

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

      KneelLogger.log('✅ Phone authentication successful', context: 'PhoneAuth');
      return _mapFirebaseUser(firebaseUser);
    } on firebase.FirebaseAuthException catch (e) {
      KneelLogger.error('PhoneAuth: verifyPhoneCode failed - ${e.code}', e.message);
      if (e.code == 'invalid-verification-code') {
        throw Exception('Invalid code. Please check and try again.');
      } else if (e.code == 'session-expired' || e.message?.contains('expired') == true) {
        throw Exception('Code expired. Tap "Resend Code" to get a new one.');
      } else if (e.code == 'credential-already-in-use') {
        throw Exception('This phone is linked to another account.');
      }
      rethrow;
    } catch (e) {
      KneelLogger.error('PhoneAuth: verifyPhoneCode exception', e);
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
      KneelLogger.biometric('Attempting biometric login...');

      // Step 1: Check if biometric login is enabled with stored token
      final isEnabled = await _biometricService.isBiometricLoginEnabled();
      if (!isEnabled) {
        throw Exception('Biometric login is not enabled. Please sign in first.');
      }

      // Step 2: Verify biometrics
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to sign in to Kneel',
      );

      if (!authenticated) {
        throw Exception('Biometric authentication failed');
      }

      // Step 3: Check if there's already an active Firebase session
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        KneelLogger.biometric('Using existing Firebase session');
        await _saveSessionInfo(currentUser.uid);
        return _mapFirebaseUser(currentUser);
      }

      // Step 4: Get stored refresh token and restore session
      final refreshToken = await _biometricService.getStoredRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        // Token was cleared - disable biometric login
        await _biometricService.disableBiometricLogin();
        throw Exception('Session expired. Please sign in again.');
      }

      // Step 5: Sign in with the stored token
      // Firebase doesn't have a direct signInWithRefreshToken method,
      // but we can use signInWithCustomToken if we have backend support.
      // For now, we'll use the stored user ID to verify and trust the session.
      final storedUserId = await _biometricService.getStoredUserId();
      if (storedUserId == null) {
        await _biometricService.disableBiometricLogin();
        throw Exception('Session data corrupted. Please sign in again.');
      }

      // Since Firebase persists auth state, if we reach here without a currentUser,
      // it means the session truly expired. Clear biometric data and ask to re-login.
      await _biometricService.disableBiometricLogin();
      throw Exception('Session expired. Please sign in again to re-enable one-touch login.');
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
  Future<bool> isBiometricLoginEnabled() async {
    return _biometricService.isBiometricLoginEnabled();
  }

  @override
  Future<bool> hasPreviousSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSessionKey) ?? false;
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return null;

      // Get the ID token which can be used to restore the session
      final idToken = await currentUser.getIdToken(true);
      return idToken;
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.getRefreshToken', e);
      return null;
    }
  }

  @override
  Future<bool> enableBiometricLogin() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        KneelLogger.warn('Cannot enable biometric login: No user signed in', context: 'Auth');
        return false;
      }

      // Get the refresh token (ID token for session restoration)
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        KneelLogger.warn('Cannot enable biometric login: Failed to get token', context: 'Auth');
        return false;
      }

      // Enable biometric login (this will verify biometrics and store token)
      final success = await _biometricService.enableBiometricLogin(
        refreshToken: refreshToken,
        userId: currentUser.uid,
      );

      if (success) {
        KneelLogger.log('Biometric login enabled for user: ${currentUser.uid}', context: 'Auth');
      }

      return success;
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.enableBiometricLogin', e);
      return false;
    }
  }

  @override
  Future<void> disableBiometricLogin() async {
    try {
      await _biometricService.disableBiometricLogin();
      KneelLogger.log('Biometric login disabled', context: 'Auth');
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.disableBiometricLogin', e);
    }
  }

  // ===== Phone Linking (Add phone to existing account) =====

  @override
  Future<void> linkPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
    Function()? onLinkSuccess,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        onVerificationFailed('No user signed in');
        return;
      }

      KneelLogger.log('Linking phone number: $phoneNumber', context: 'Auth');

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (firebase.PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          KneelLogger.log('Phone auto-verification completed', context: 'Auth');
          try {
            await currentUser.linkWithCredential(credential);
            KneelLogger.log('Phone linked successfully (auto)', context: 'Auth');
            onLinkSuccess?.call();
          } catch (e) {
            KneelLogger.error('Auto-link failed', e);
            onVerificationFailed(_parseFirebaseError(e));
          }
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          KneelLogger.error('Phone verification failed', e.message);
          onVerificationFailed(_parsePhoneVerificationError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          KneelLogger.log('Verification code sent for linking', context: 'Auth');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          KneelLogger.log('Auto-retrieval timeout', context: 'Auth');
        },
      );
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.linkPhoneNumber', e);
      onVerificationFailed(e.toString());
    }
  }

  @override
  Future<void> verifyAndLinkPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      KneelLogger.log('Verifying and linking phone...', context: 'Auth');

      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await currentUser.linkWithCredential(credential);
      KneelLogger.log('Phone linked successfully', context: 'Auth');
    } on firebase.FirebaseAuthException catch (e) {
      KneelLogger.error('FirebaseAuthService.verifyAndLinkPhone', e.message);
      if (e.code == 'invalid-verification-code') {
        throw Exception('Invalid verification code. Please try again.');
      } else if (e.code == 'session-expired') {
        throw Exception('Verification code expired. Please request a new code.');
      } else if (e.code == 'credential-already-in-use') {
        throw Exception('This phone number is already linked to another account.');
      } else if (e.code == 'provider-already-linked') {
        throw Exception('A phone number is already linked to this account.');
      }
      rethrow;
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.verifyAndLinkPhone', e);
      rethrow;
    }
  }

  // ===== Password Management =====

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      final email = currentUser.email;
      if (email == null || email.isEmpty) {
        throw Exception('No email associated with this account');
      }

      KneelLogger.log('Updating password for: $email', context: 'Auth');

      // Re-authenticate with current password
      final credential = firebase.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await currentUser.reauthenticateWithCredential(credential);

      // Update to new password
      await currentUser.updatePassword(newPassword);
      KneelLogger.log('Password updated successfully', context: 'Auth');
    } on firebase.FirebaseAuthException catch (e) {
      KneelLogger.error('FirebaseAuthService.updatePassword', e.message);
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect.');
      } else if (e.code == 'weak-password') {
        throw Exception('New password is too weak. Use at least 6 characters.');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Please sign out and sign in again before changing password.');
      }
      rethrow;
    } catch (e) {
      KneelLogger.error('FirebaseAuthService.updatePassword', e);
      rethrow;
    }
  }

  String _parsePhoneVerificationError(firebase.FirebaseAuthException e) {
    if (e.code == 'invalid-phone-number') {
      return 'Invalid phone number format';
    } else if (e.code == 'too-many-requests') {
      return 'Too many requests. Please try again later.';
    } else if (e.message != null) {
      return e.message!;
    }
    return 'Verification failed';
  }

  String _parseFirebaseError(dynamic e) {
    if (e is firebase.FirebaseAuthException) {
      return e.message ?? e.code;
    }
    return e.toString();
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
      KneelLogger.log('[1/4] Google Sign-In disconnected', context: 'Auth');
    } catch (e) {
      KneelLogger.warn('[1/4] Google disconnect failed (may not be signed in): $e', context: 'Auth');
      // Not a critical failure - user might not have used Google
    }

    // Step 2: Sign out from Firebase Auth
    try {
      await _firebaseAuth.signOut();
      KneelLogger.log('[2/4] Firebase Auth signed out', context: 'Auth');
    } catch (e) {
      KneelLogger.error('[2/4] Firebase signOut failed', e);
      success = false;
    }

    // Step 3: Clear biometric credentials from secure storage
    try {
      await _biometricService.clearAllCredentials();
      KneelLogger.log('[3/4] Biometric credentials cleared', context: 'Auth');
    } catch (e) {
      KneelLogger.error('[3/4] Biometric credentials clear failed', e);
      // Not critical - continue with reset
    }

    // Step 4: Clear ALL SharedPreferences (nuclear option)
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear specific session keys
      await prefs.remove(_lastUserIdKey);
      await prefs.remove(_hasSessionKey);
      // Reset session flag explicitly
      await prefs.setBool(_hasSessionKey, false);
      // Optionally clear ALL prefs for complete reset (uncomment if needed)
      // await prefs.clear();
      KneelLogger.log('[4/4] SharedPreferences cleared', context: 'Auth');
    } catch (e) {
      KneelLogger.error('[4/4] SharedPreferences clear failed', e);
      success = false;
    }

    KneelLogger.log('=== SESSION RESET ${success ? 'COMPLETE' : 'PARTIAL'} ===', context: 'Auth');
    return success;
  }

  // ===== Private Helpers =====

  /// Maps a Firebase user to our domain User entity.
  /// Phone numbers are sanitized using the Safe-Save Rule (null if empty).
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

    // Try to extract phone from provider data (Google may have linked phone)
    String? phoneFromProvider;
    for (final providerInfo in firebaseUser.providerData) {
      if (providerInfo.phoneNumber != null && providerInfo.phoneNumber!.isNotEmpty) {
        phoneFromProvider = providerInfo.phoneNumber;
        break;
      }
    }

    // Safe-Save Rule: Sanitize phone to prevent empty string issues
    final sanitizedPhone = User.sanitizePhone(
      firebaseUser.phoneNumber ?? phoneFromProvider,
    );

    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'Prayer Warrior',
      photoUrl: firebaseUser.photoURL,
      phoneNumber: sanitizedPhone,
      provider: provider,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      isEmailVerified: firebaseUser.emailVerified,
    );
  }

  /// Syncs the Firebase user profile to Supabase.
  ///
  /// IDENTITY SYNC: If user already exists in Supabase, MERGE the data
  /// instead of overwriting their existing Bio/Location with defaults.
  ///
  /// PHONE NUMBER PRIORITY (Safe-Save Rule):
  /// 1. Firebase user's phoneNumber (if signed in with phone)
  /// 2. Phone from provider data (Google may have linked phone)
  /// 3. Existing database phone number
  /// Empty strings are converted to NULL to prevent unique constraint violations.
  Future<void> _syncProfileToSupabase(firebase.User firebaseUser, String provider) async {
    try {
      // First, check if user already has a profile
      final existingProfile = await _profileService.getProfile(firebaseUser.uid);

      // Extract phone from provider data (in case Google has linked phone)
      String? phoneFromProvider;
      for (final providerInfo in firebaseUser.providerData) {
        final phone = User.sanitizePhone(providerInfo.phoneNumber);
        if (phone != null) {
          phoneFromProvider = phone;
          KneelLogger.log('Found phone from provider: ${providerInfo.providerId}', context: 'Auth');
          break;
        }
      }

      if (existingProfile != null) {
        // MERGE: Preserve existing bio, location, and other user data
        KneelLogger.log('Merging with existing Supabase profile', context: 'Auth');

        // Phone merge with priority: Firebase > ProviderData > Existing
        final mergedPhone = User.mergePhone(
          userInput: null, // No user input during auth sync
          authProviderPhone: firebaseUser.phoneNumber ?? phoneFromProvider,
          existingDatabasePhone: existingProfile.phoneNumber,
        );

        await _profileService.upsertProfile(
          uid: firebaseUser.uid,
          email: firebaseUser.email?.isNotEmpty == true
              ? firebaseUser.email!
              : existingProfile.email,
          displayName: firebaseUser.displayName ?? existingProfile.displayName,
          photoUrl: firebaseUser.photoURL ?? existingProfile.photoUrl,
          provider: provider,
          phoneNumber: mergedPhone, // Uses Safe-Save merged value
          // PRESERVE existing user-entered data
          bio: existingProfile.bio,
          locationCity: existingProfile.locationCity,
          googlePlaceId: existingProfile.googlePlaceId,
          emailVerified: firebaseUser.emailVerified || existingProfile.emailVerified,
        );
      } else {
        // New user - create profile with Firebase data
        KneelLogger.log('Creating new Supabase profile', context: 'Auth');

        // Safe-Save: Sanitize phone from Firebase
        final sanitizedPhone = User.sanitizePhone(
          firebaseUser.phoneNumber ?? phoneFromProvider,
        );

        await _profileService.upsertProfile(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          provider: provider,
          phoneNumber: sanitizedPhone, // NULL if empty (Safe-Save Rule)
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
