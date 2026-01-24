import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:quick_church/core/theme/app_theme.dart';
import 'package:quick_church/features/prayer/presentation/bloc/prayer_cubit.dart';
import 'package:quick_church/features/prayer/presentation/bloc/session_cubit.dart';
import 'package:quick_church/features/prayer/presentation/pages/main_navigation_page.dart';
import 'package:quick_church/features/prayer/presentation/pages/splash_page.dart';
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
  runApp(const QuickChurchApp());
}

/// Root application widget for QuickChurch.
///
/// Configures theming, routing, and provides the root BLoC.
class QuickChurchApp extends StatefulWidget {
  const QuickChurchApp({super.key});

  @override
  State<QuickChurchApp> createState() => _QuickChurchAppState();
}

class _QuickChurchAppState extends State<QuickChurchApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kneel',
      debugShowCheckedModeBanner: false,

      // Theme configuration with Material 3
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Home page with BLoC providers
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => getIt<PrayerCubit>()..loadPrayers(),
          ),
          BlocProvider(
            create: (_) => getIt<SessionCubit>()..loadSessions(),
          ),
        ],
        child: _showSplash
            ? SplashPage(
                onInitComplete: () {
                  setState(() => _showSplash = false);
                },
              )
            : const MainNavigationPage(),
      ),
    );
  }
}
