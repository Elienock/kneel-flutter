import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Kneel'**
  String get appTitle;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Prayers tab label
  ///
  /// In en, this message translates to:
  /// **'Prayers'**
  String get prayers;

  /// Community tab label
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// Insights tab label
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// Profile tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Welcome screen title
  ///
  /// In en, this message translates to:
  /// **'Your Personal Prayer Companion'**
  String get welcomeTitle;

  /// Welcome screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Track your prayers, build spiritual habits,\nand grow in faith together.'**
  String get welcomeSubtitle;

  /// Google sign in button text
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Phone sign in button text
  ///
  /// In en, this message translates to:
  /// **'Use Phone Number'**
  String get usePhoneNumber;

  /// Email sign in button text
  ///
  /// In en, this message translates to:
  /// **'Email Login'**
  String get emailLogin;

  /// Biometric login button text
  ///
  /// In en, this message translates to:
  /// **'Login with Biometrics'**
  String get loginWithBiometrics;

  /// Terms and privacy policy text
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service\nand Privacy Policy'**
  String get termsText;

  /// Loading text during sign in
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// Prayer streak card title
  ///
  /// In en, this message translates to:
  /// **'Prayer Streak'**
  String get prayerStreak;

  /// Prayer streak card subtitle
  ///
  /// In en, this message translates to:
  /// **'Keep your prayer habit going'**
  String get keepHabitGoing;

  /// Day streak label
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get dayStreak;

  /// Times prayed label
  ///
  /// In en, this message translates to:
  /// **'Times Prayed'**
  String get timesPrayed;

  /// Answered prayers label
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// Active prayers label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Urgent prayers label
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// Guided sessions section title
  ///
  /// In en, this message translates to:
  /// **'Guided Sessions'**
  String get guidedSessions;

  /// Recent prayers section title
  ///
  /// In en, this message translates to:
  /// **'Recent Prayers'**
  String get recentPrayers;

  /// See all button text
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No prayers yet'**
  String get noPrayersYet;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Add your first prayer request'**
  String get addFirstPrayer;

  /// New prayer button text
  ///
  /// In en, this message translates to:
  /// **'New Prayer'**
  String get newPrayer;

  /// Quick pray button text
  ///
  /// In en, this message translates to:
  /// **'Quick Pray'**
  String get quickPray;

  /// Focus page title
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// Sacred timer card title
  ///
  /// In en, this message translates to:
  /// **'Sacred Timer'**
  String get sacredTimer;

  /// Duration selection prompt
  ///
  /// In en, this message translates to:
  /// **'How long would you like to dwell in prayer?'**
  String get howLongToPray;

  /// Duration selection label
  ///
  /// In en, this message translates to:
  /// **'Select Duration'**
  String get selectDuration;

  /// Start focus session button
  ///
  /// In en, this message translates to:
  /// **'Begin Prayer Time'**
  String get beginPrayerTime;

  /// Prayer queue section title
  ///
  /// In en, this message translates to:
  /// **'Prayer Queue'**
  String get prayerQueue;

  /// Empty focus state title
  ///
  /// In en, this message translates to:
  /// **'No Active Prayers'**
  String get noActivePrayers;

  /// Empty focus state subtitle
  ///
  /// In en, this message translates to:
  /// **'Add prayers to enter focus mode'**
  String get addPrayersToFocus;

  /// Prayed action button
  ///
  /// In en, this message translates to:
  /// **'Prayed'**
  String get prayed;

  /// Session complete title
  ///
  /// In en, this message translates to:
  /// **'Session Complete'**
  String get sessionComplete;

  /// Keep going button
  ///
  /// In en, this message translates to:
  /// **'Keep Going'**
  String get keepGoing;

  /// Finish button
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// Exit confirmation title
  ///
  /// In en, this message translates to:
  /// **'End Prayer Time?'**
  String get endPrayerTime;

  /// Continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Save and exit button
  ///
  /// In en, this message translates to:
  /// **'Save & Exit'**
  String get saveAndExit;

  /// Exit button
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Reminder settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Reminder settings'**
  String get reminderSettings;

  /// Biometric lock setting
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get biometricLock;

  /// Biometric lock subtitle
  ///
  /// In en, this message translates to:
  /// **'Secure with fingerprint/face'**
  String get secureWithBiometric;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Backup setting
  ///
  /// In en, this message translates to:
  /// **'Backup & Export'**
  String get backupAndExport;

  /// Backup subtitle
  ///
  /// In en, this message translates to:
  /// **'Export your prayer data'**
  String get exportYourData;

  /// Help setting
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpAndFaq;

  /// Help subtitle
  ///
  /// In en, this message translates to:
  /// **'Get support'**
  String get getSupport;

  /// Privacy policy setting
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// About setting
  ///
  /// In en, this message translates to:
  /// **'About Kneel'**
  String get aboutKneel;

  /// Sign out button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Sign out confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Morning reminders setting
  ///
  /// In en, this message translates to:
  /// **'Morning Reminders'**
  String get morningReminders;

  /// Morning reminders subtitle
  ///
  /// In en, this message translates to:
  /// **'Daily prayer reminder'**
  String get dailyPrayerReminder;

  /// Reminder time setting
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// Answered alerts setting
  ///
  /// In en, this message translates to:
  /// **'Answered Prayer Alerts'**
  String get answeredPrayerAlerts;

  /// Answered alerts subtitle
  ///
  /// In en, this message translates to:
  /// **'Celebrate answered prayers'**
  String get celebrateAnswered;

  /// CSV export option
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportAsCsv;

  /// JSON export option
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get exportAsJson;

  /// JSON import option
  ///
  /// In en, this message translates to:
  /// **'Import from JSON'**
  String get importFromJson;

  /// Export success message
  ///
  /// In en, this message translates to:
  /// **'Export Successful!'**
  String get exportSuccess;

  /// My groups section
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get myGroups;

  /// Create button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Shared intentions section
  ///
  /// In en, this message translates to:
  /// **'Shared Intentions'**
  String get sharedIntentions;

  /// Praying count suffix
  ///
  /// In en, this message translates to:
  /// **'praying'**
  String get praying;

  /// Pray button
  ///
  /// In en, this message translates to:
  /// **'Pray'**
  String get pray;

  /// Coming soon badge
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Total stat label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Streak stat label
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// Heatmap section title
  ///
  /// In en, this message translates to:
  /// **'Activity Heatmap'**
  String get activityHeatmap;

  /// Month calendar section
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// Weekly trend section
  ///
  /// In en, this message translates to:
  /// **'Weekly Trend'**
  String get weeklyTrend;

  /// Heatmap legend less
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// Heatmap legend more
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Session type
  ///
  /// In en, this message translates to:
  /// **'Scripture Meditation'**
  String get scriptureMeditation;

  /// Session type
  ///
  /// In en, this message translates to:
  /// **'Guided Prayer'**
  String get guidedPrayer;

  /// Session type
  ///
  /// In en, this message translates to:
  /// **'Worship Session'**
  String get worshipSession;

  /// Session type
  ///
  /// In en, this message translates to:
  /// **'Breathing Exercise'**
  String get breathingExercise;

  /// Duration in minutes
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String minutes(int count);

  /// Minutes abbreviation
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// Begin session button
  ///
  /// In en, this message translates to:
  /// **'Begin Session'**
  String get beginSession;

  /// Premium unlock button
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium'**
  String get unlockPremium;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
