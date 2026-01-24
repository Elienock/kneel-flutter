import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:quick_church/features/prayer/data/models/prayer_model.dart';
import 'package:quick_church/features/prayer/data/models/prayer_session_model.dart';

/// Module for registering third-party dependencies that cannot be annotated directly.
@module
abstract class RegisterModule {
  /// Provides UUID generator instance for creating unique IDs.
  @lazySingleton
  Uuid get uuid => const Uuid();

  /// Provides the Hive box for storing PrayerModel instances.
  /// The box is opened asynchronously during app initialization.
  @preResolve
  @lazySingleton
  Future<Box<PrayerModel>> get prayerBox => Hive.openBox<PrayerModel>('prayers');

  /// Provides the Hive box for storing PrayerSessionModel instances.
  /// Used for tracking focus mode sessions and calendar data.
  @preResolve
  @lazySingleton
  Future<Box<PrayerSessionModel>> get sessionBox => Hive.openBox<PrayerSessionModel>('prayer_sessions');
}
