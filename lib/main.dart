import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quick_church/core/services/app_lifecycle_observer.dart';
import 'package:quick_church/core/services/interfaces/i_biometric_service.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/core/utils/kneel_logger.dart';
import 'package:quick_church/core/widgets/kneel_logo.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_state.dart';
import 'package:quick_church/features/auth/presentation/pages/auth_page.dart';
import 'package:quick_church/features/auth/presentation/pages/onboarding_page.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/session_cubit.dart';
import 'package:quick_church/features/prayer/presentation/pages/main_navigation_page.dart';
import 'package:quick_church/features/prayer/presentation/pages/splash_page.dart';
import 'package:quick_church/features/profile/presentation/bloc/language_cubit.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:quick_church/features/profile/presentation/bloc/profile_state.dart';
import 'package:quick_church/features/sermon/presentation/bloc/sermon_cubit.dart';
import 'package:quick_church/features/insights/presentation/bloc/insights_cubit.dart';
import 'package:quick_church/features/pulpit/presentation/bloc/pulpit_cubit.dart';
import 'package:quick_church/features/community/presentation/bloc/community_cubit.dart';
import 'package:quick_church/features/focus/presentation/bloc/focus_cubit.dart';
import 'package:quick_church/injection.dart';

void main() async {
  // Preserve splash screen while initializing
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Set preferred orientations for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize dependency injection (Hive + GetIt + Firebase + Supabase)
  await configureDependencies();

  // Remove splash screen after initialization complete
  FlutterNativeSplash.remove();

  // Run the app
  runApp(const KneelApp());
}

/// Root application widget for Kneel.
///
/// Configures theming, routing, localization, and provides the root BLoCs.
/// Includes AppLifecycleObserver for session persistence.
class KneelApp extends StatefulWidget {
  const KneelApp({super.key});

  @override
  State<KneelApp> createState() => _KneelAppState();
}

class _KneelAppState extends State<KneelApp> {
  bool _showSplash = true;
  late final AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    // Initialize lifecycle observer for session management
    _lifecycleObserver = AppLifecycleObserver(
      onSessionExpired: _handleSessionExpired,
      onSessionRefreshed: _handleSessionRefreshed,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    KneelLogger.lifecycle('AppLifecycleObserver registered');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  void _handleSessionExpired() {
    KneelLogger.lifecycle('Session expired - triggering logout');
    // The auth cubit will handle this via Firebase auth state changes
  }

  void _handleSessionRefreshed() {
    KneelLogger.lifecycle('Session refreshed successfully');
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LanguageCubit(),
        ),
        BlocProvider(
          create: (_) => getIt<AuthCubit>()..init(),
        ),
        BlocProvider(
          create: (_) => getIt<ProfileCubit>(),
        ),
        BlocProvider(
          create: (_) => getIt<PrayerCubit>()..loadPrayers(),
        ),
        BlocProvider(
          create: (_) => getIt<SessionCubit>()..loadSessions(),
        ),
        BlocProvider(
          create: (_) => getIt<SermonCubit>()..loadSermons(),
        ),
        BlocProvider(
          create: (_) => getIt<InsightsCubit>(),
        ),
        BlocProvider(
          create: (_) => PulpitCubit()..loadGroups(),
        ),
        BlocProvider(
          create: (_) => CommunityCubit()..loadAll(),
        ),
        BlocProvider(
          create: (_) => getIt<FocusCubit>()..loadData(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Wire up FocusCubit -> PrayerCubit callback for specific prayer completion
          final focusCubit = context.read<FocusCubit>();
          final prayerCubit = context.read<PrayerCubit>();
          focusCubit.onPrayerCompleted = (prayerId) {
            prayerCubit.incrementPrayerCount(prayerId);
          };

          return BlocBuilder<LanguageCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                title: 'Kneel',
                debugShowCheckedModeBanner: false,

                // Localization configuration
                locale: locale,
                supportedLocales: LanguageCubit.supportedLocales,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                // Theme configuration with Material 3
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.system,

                // Auth-aware home
                home: _showSplash
                    ? SplashPage(
                        onInitComplete: () {
                          setState(() => _showSplash = false);
                        },
                      )
                    : const _AuthGate(),
              );
            },
          );
        },
      ),
    );
  }
}

/// Smart Router - Gates the app based on Auth + Profile + Biometric state.
///
/// Navigation Logic:
/// - NOT Signed In → AuthPage
/// - Signed In + Biometric Enabled + Not Verified → BiometricChallenge
/// - Signed In + Profile Loading → Loading Screen
/// - Signed In + Profile Connection Error → Retry Screen
/// - Signed In + Profile Incomplete → OnboardingPage
/// - Signed In + Profile Complete (validated) → MainNavigationPage
///
/// Uses StatefulWidget to track profile load status and prevent double-login loops.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _profileLoadTriggered = false;
  bool _biometricVerified = false;
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    // Check if already authenticated when widget mounts
    // This handles the case where auth state was set before this widget rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuthState();
    });
  }

  /// Checks auth state on mount - handles case where Authenticated was emitted
  /// before this widget's BlocListener was active (e.g., during splash screen)
  ///
  /// PRODUCTION HARDENED: Uses mounted check and microtask for stability
  void _checkInitialAuthState() {
    final authState = context.read<AuthCubit>().state;
    KneelLogger.log('initState check - authState is ${authState.runtimeType}', context: 'SmartRouter');

    if (authState is Authenticated && !_profileLoadTriggered) {
      _profileLoadTriggered = true;
      final user = authState.user;
      KneelLogger.log('Already authenticated! Triggering loadProfile for ${user.id}', context: 'SmartRouter');

      // PRODUCTION STABILITY: Ensure context is still valid
      if (mounted) {
        context.read<ProfileCubit>().loadProfile(
          uid: user.id,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          provider: user.provider.name,
          phoneNumber: user.phoneNumber,
          emailVerified: user.isEmailVerified,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, authState) {
        // When user signs out, reset all flags
        if (authState is Unauthenticated || authState is AuthInitial) {
          KneelLogger.log('Auth state: ${authState.runtimeType} - resetting SmartRouter', context: 'SmartRouter');
          _profileLoadTriggered = false;
          _biometricVerified = false;
          _checkingBiometric = false;
          context.read<ProfileCubit>().clear();
        }

        // When user authenticates, load their profile (only once per session)
        if (authState is Authenticated && !_profileLoadTriggered) {
          _profileLoadTriggered = true;
          final user = authState.user;
          KneelLogger.log('Auth state changed to Authenticated, loading profile for ${user.id}', context: 'SmartRouter');

          // PRODUCTION STABILITY: Small delay to ensure state is stable
          // This prevents race conditions during rapid auth state changes
          Future.microtask(() {
            if (context.mounted) {
              context.read<ProfileCubit>().loadProfile(
                uid: user.id,
                email: user.email,
                displayName: user.displayName,
                photoUrl: user.photoUrl,
                provider: user.provider.name,
                phoneNumber: user.phoneNumber,
                emailVerified: user.isEmailVerified,
              );
            }
          });
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // ═══════════════════════════════════════════════════════════════════
          // BRANCH 1: Not authenticated → Show Auth Page
          // ═══════════════════════════════════════════════════════════════════
          if (authState is AuthInitial || authState is Unauthenticated || authState is AuthError) {
            return const AuthPage();
          }

          // ═══════════════════════════════════════════════════════════════════
          // BRANCH 2: Auth Loading → Show branded loading
          // ═══════════════════════════════════════════════════════════════════
          if (authState is AuthLoading) {
            return const _BrandedLoadingScreen(message: 'Signing in...');
          }

          // ═══════════════════════════════════════════════════════════════════
          // BRANCH 3: Authenticated → Check Profile State (Smart Routing)
          // ═══════════════════════════════════════════════════════════════════
          if (authState is Authenticated) {
            return BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                // 3a. Profile loading → Branded loading screen
                if (profileState is ProfileLoading || profileState is ProfileInitial) {
                  return const _BrandedLoadingScreen(message: 'Loading your profile...');
                }

                // 3b. Profile connection error → Retry screen
                if (profileState is ProfileConnectionError) {
                  return _ConnectionErrorScreen(
                    message: profileState.message,
                    onRetry: () {
                      context.read<ProfileCubit>().retryProfileLoad();
                    },
                  );
                }

                // 3b2. Profile not found (user deleted) → Self-Healing in progress
                if (profileState is ProfileNotFound) {
                  KneelLogger.warn('ProfileNotFound - self-healing in progress', context: 'SmartRouter');
                  // Self-healing auto-triggers in ProfileCubit._handleUserNotFound()
                  // This screen shows briefly while session is being cleared
                  return _AccountDeletedScreen(
                    message: profileState.message,
                    onSignInAgain: () {
                      // Manual trigger if auto-heal didn't complete
                      context.read<ProfileCubit>().forceLogoutAndClearAllData();
                    },
                  );
                }

                // 3c. Profile incomplete → Onboarding (wrapped with PopScope)
                if (profileState is ProfileNeedsOnboarding) {
                  return OnboardingPage(
                    initialPhotoUrl: authState.user.photoUrl,
                    initialDisplayName: authState.user.displayName,
                  );
                }

                // 3d. Profile complete → Validate & Show Home
                if (profileState is ProfileLoaded || profileState is ProfileUpdating) {
                  final profile = profileState is ProfileLoaded
                      ? profileState.profile
                      : (profileState as ProfileUpdating).currentProfile;

                  // STATE VALIDATION: Ensure critical fields are present
                  // PRODUCTION FIX: Don't call loadProfile() again - causes race conditions
                  // Instead, show onboarding directly if profile is incomplete
                  if (!profile.isProfileComplete) {
                    KneelLogger.warn(
                      'Profile incomplete in ProfileLoaded state - showing onboarding',
                      context: 'SmartRouter',
                    );
                    // Show onboarding directly instead of reloading profile
                    // This prevents the race condition where loadProfile() can trigger
                    // a sign-out if Firebase session becomes invalid during transition
                    return OnboardingPage(
                      initialPhotoUrl: profile.photoUrl,
                      initialDisplayName: profile.displayName,
                    );
                  }

                  // Profile is valid - show Home
                  return const MainNavigationPage();
                }

                // 3e. Profile error → Error screen with retry
                if (profileState is ProfileError) {
                  return _ErrorScreen(
                    message: profileState.message,
                    onRetry: () {
                      final user = authState.user;
                      context.read<ProfileCubit>().loadProfile(
                        uid: user.id,
                        email: user.email,
                        displayName: user.displayName,
                        photoUrl: user.photoUrl,
                        provider: user.provider.name,
                        phoneNumber: user.phoneNumber,
                        emailVerified: user.isEmailVerified,
                      );
                    },
                  );
                }

                // Fallback loading
                return const _BrandedLoadingScreen(message: 'Please wait...');
              },
            );
          }

          // Fallback (should never reach)
          return const _BrandedLoadingScreen(message: 'Starting...');
        },
      ),
    );
  }

  /// Checks if biometric should be challenged and triggers it.
  ///
  /// This is called when user has enabled biometric lock in settings.
  /// Currently a placeholder - enable when biometric lock feature is implemented.
  // ignore: unused_element
  Future<void> _checkBiometricChallenge() async {
    if (_biometricVerified || _checkingBiometric) return;

    setState(() => _checkingBiometric = true);

    try {
      final biometricService = getIt<IBiometricService>();
      final canUseBiometric = await biometricService.isAvailable();
      final hasBiometrics = await biometricService.hasEnrolledBiometrics();

      if (canUseBiometric && hasBiometrics) {
        // TODO: Check user preference for biometric lock in settings
        // For now, we skip biometric challenge on fresh login
        // Biometric is only used for re-authentication from locked state
        KneelLogger.biometric('Biometric available: $canUseBiometric, enrolled: $hasBiometrics');
      }

      _biometricVerified = true;
    } catch (e) {
      KneelLogger.error('BiometricChallenge', e);
      _biometricVerified = true; // Skip on error
    } finally {
      if (mounted) {
        setState(() => _checkingBiometric = false);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UI SCREENS (Optimized for 60fps)
// ═══════════════════════════════════════════════════════════════════════════════

/// Kneel-branded loading screen with fade-in animation.
/// Optimized with RepaintBoundary for smooth 60fps performance.
/// Includes debug "Hard Reset" button in kDebugMode.
class _BrandedLoadingScreen extends StatelessWidget {
  final String message;

  const _BrandedLoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.15),
              isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Official Kneel Logo with animation (wrapped in RepaintBoundary)
                    // Uses dark background variant with elevation for the loading screen
                    RepaintBoundary(
                      child: AnimatedKneelLogo(
                        logo: KneelLogo.dark(
                          height: 120,
                          showElevation: true,
                          elevation: 10,
                          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App name (wrapped in RepaintBoundary)
                    RepaintBoundary(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: child,
                          );
                        },
                        child: Text(
                          'Kneel',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Loading indicator (wrapped in RepaintBoundary for animation isolation)
                    RepaintBoundary(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message
                    Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),

              // DEBUG ONLY: Ghost Reset button (bottom-right corner)
              // Wrapped in kDebugMode so it's physically removed from production binary
              if (kDebugMode)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () async {
                      KneelLogger.log('Ghost Reset triggered (debug)', context: 'Debug');
                      await context.read<ProfileCubit>().forceLogoutAndClearAllData();
                    },
                    icon: Icon(
                      Icons.refresh,
                      size: 20,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    tooltip: 'Debug Reset',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Connection error screen with retry button (for timeout/network issues).
class _ConnectionErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ConnectionErrorScreen({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Connection icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      LucideIcons.wifiOff,
                      color: Colors.orange,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Connection Issue',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(LucideIcons.refreshCw, size: 20),
                      label: Text(
                        'Retry Connection',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hint text
                  Text(
                    'Check your internet connection and try again',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Error screen with retry option.
class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.withValues(alpha: 0.1),
              isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      LucideIcons.alertTriangle,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Something went wrong',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 40),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(LucideIcons.refreshCw, size: 20),
                      label: Text(
                        'Try Again',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Account deleted screen - shown when user's backend profile is not found.
/// Triggers force logout and returns user to sign in.
class _AccountDeletedScreen extends StatelessWidget {
  final String message;
  final VoidCallback onSignInAgain;

  const _AccountDeletedScreen({
    required this.message,
    required this.onSignInAgain,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.withValues(alpha: 0.15),
              isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Account icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      LucideIcons.userX,
                      color: Colors.orange,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Account Not Found',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Sign in again button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: onSignInAgain,
                      icon: const Icon(LucideIcons.logIn, size: 20),
                      label: Text(
                        'Sign In Again',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hint text
                  Text(
                    'Your session has expired or account was removed.\nPlease sign in to continue.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
