import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quick_church/core/config/env_config.dart';
import 'package:quick_church/core/utils/debug_logger.dart';
import 'package:quick_church/features/prayer/data/models/prayer_model.dart';
import 'package:quick_church/features/prayer/data/models/prayer_session_model.dart';
import 'package:quick_church/features/sermon/data/models/sermon_note_model.dart';
import 'package:quick_church/injection.config.dart';

/// Global service locator instance.
final getIt = GetIt.instance;

/// Configures all dependencies for the application.
///
/// This function initializes Hive for local storage, Firebase, Supabase,
/// and registers all injectable dependencies using the generated configuration.
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  DebugLogger.firebaseInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );
  DebugLogger.supabaseConnected();

  // Initialize Hive for Flutter
  await Hive.initFlutter();

  // Register Hive type adapters for Prayer models
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PrayerStatusModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(PrayerPriorityModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(PrayerModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(PrayerSessionModelAdapter());
  }

  // Register Hive type adapter for Sermon notes
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(SermonNoteModelAdapter());
  }

  // Initialize all injectable dependencies (async for @preResolve)
  await getIt.init();
}
