import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:quick_church/features/auth/presentation/bloc/auth_state.dart';
import 'package:quick_church/features/auth/presentation/pages/auth_page.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/session_cubit.dart';
import 'package:quick_church/features/prayer/presentation/pages/main_navigation_page.dart';
import 'package:quick_church/features/prayer/presentation/pages/splash_page.dart';
import 'package:quick_church/features/profile/presentation/bloc/language_cubit.dart';
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

  // Initialize dependency injection (Hive + GetIt)
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
          create: (_) => getIt<PrayerCubit>()..loadPrayers(),
        ),
        BlocProvider(
          create: (_) => getIt<SessionCubit>()..loadSessions(),
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

/// Gates the main app behind authentication.
/// Shows AuthPage when unauthenticated, MainNavigationPage when authenticated.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const _LoadingScreen();
        }

        if (state is Authenticated) {
          return const MainNavigationPage();
        }

        return const AuthPage();
      },
    );
  }
}

/// Premium loading screen during authentication.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

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
                'Signing in...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
