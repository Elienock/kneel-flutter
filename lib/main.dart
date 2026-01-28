import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_church/core/theme/app_theme.dart';
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
class KneelApp extends StatefulWidget {
  const KneelApp({super.key});

  @override
  State<KneelApp> createState() => _KneelAppState();
}

class _KneelAppState extends State<KneelApp> {
  bool _showSplash = true;

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
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
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
      ),
    );
  }
}

/// Gates the main app behind authentication and onboarding.
/// Shows AuthPage when unauthenticated, OnboardingPage when needs onboarding,
/// MainNavigationPage when fully authenticated.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, authState) {
        // When user authenticates, load their profile
        if (authState is Authenticated) {
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
        }
      },
      builder: (context, authState) {
        if (authState is AuthLoading) {
          return const _LoadingScreen(message: 'Signing in...');
        }

        if (authState is Authenticated) {
          // Check profile state for onboarding
          return BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              if (profileState is ProfileLoading || profileState is ProfileInitial) {
                return const _LoadingScreen(message: 'Loading profile...');
              }

              if (profileState is ProfileNeedsOnboarding) {
                return OnboardingPage(
                  initialPhotoUrl: authState.user.photoUrl,
                  initialDisplayName: authState.user.displayName,
                );
              }

              if (profileState is ProfileLoaded || profileState is ProfileUpdating) {
                return const MainNavigationPage();
              }

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

              return const _LoadingScreen(message: 'Loading...');
            },
          );
        }

        return const AuthPage();
      },
    );
  }
}

/// Premium loading screen.
class _LoadingScreen extends StatelessWidget {
  final String message;

  const _LoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
