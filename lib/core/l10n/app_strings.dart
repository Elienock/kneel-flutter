/// Centralized strings for internationalization.
/// All user-facing strings should be defined here for easy translation.
/// Future: Replace with S.of(context) using flutter_localizations.
class AppStrings {
  // ============================================================================
  // App General
  // ============================================================================
  static const String appName = 'Kneel';
  static const String appTagline = 'Your Personal Prayer Companion';
  static const String fromClaudineTech = 'from Claudine Tech';
  static const String poweredByGoogle = 'Powered by Google';

  // ============================================================================
  // Authentication
  // ============================================================================
  static const String continueWithGoogle = 'Continue with Google';
  static const String continueWithPhone = 'Use Phone Number';
  static const String emailLogin = 'Email Login';
  static const String loginWithBiometrics = 'Login with Biometrics';
  static const String signingIn = 'Signing in...';
  static const String loadingProfile = 'Loading profile...';
  static const String loading = 'Loading...';

  // Terms
  static const String termsText = 'By continuing, you agree to our Terms of Service\nand Privacy Policy';

  // Phone Auth
  static const String phoneLogin = 'Phone Login';
  static const String enterPhoneNumber = 'Enter your phone number';
  static const String phoneNumberHint = '123 456 7890';
  static const String sendVerificationCode = 'Send Verification Code';
  static const String verifyCode = 'Verify Code';
  static const String enterVerificationCode = 'Enter verification code';
  static const String codeSentTo = 'We sent a code to';
  static const String didntReceiveCode = "Didn't receive code? Try again";
  static const String searchCountry = 'Search country...';
  static const String selectCountry = 'Select Country';

  // Email Auth
  static const String welcomeBack = 'Welcome back';
  static const String signInToContinue = 'Sign in to continue your spiritual journey';
  static const String createAccount = 'Create your account';
  static const String joinCommunity = 'Join our community of prayer warriors';
  static const String forgotPasswordTitle = 'Forgot password?';
  static const String forgotPasswordSubtitle = 'Enter your email to receive a reset link';
  static const String email = 'Email';
  static const String emailHint = 'Enter your email';
  static const String password = 'Password';
  static const String passwordHint = 'Enter your password';
  static const String confirmPassword = 'Confirm Password';
  static const String confirmPasswordHint = 'Confirm your password';
  static const String displayNameOptional = 'Display Name (optional)';
  static const String displayNameHint = 'Enter your name';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String sendResetLink = 'Send Reset Link';
  static const String forgotPassword = 'Forgot Password?';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String resetEmailSent = 'Password reset email sent! Check your inbox.';

  // ============================================================================
  // Onboarding
  // ============================================================================
  static const String stepOf = 'Step {current} of {total}';

  // Step 1: Photo
  static const String addYourPhoto = 'Add Your Photo';
  static const String photoSubtitle = 'Help your prayer community recognize you';
  static const String tapToUpload = 'Tap to upload';

  // Step 2: Bio
  static const String tellUsAboutYou = 'Tell Us About You';
  static const String bioSubtitle = 'Share a bit about yourself';
  static const String fullName = 'Full Name';
  static const String fullNameHint = 'Enter your full name';
  static const String bio = 'Bio';
  static const String bioHint = 'Share your testimony or a verse...';
  static const String defaultBio = 'I am Holy and consecrated to GOD';

  // Step 3: Location
  static const String whereAreYou = 'Where Are You?';
  static const String locationSubtitle = 'Connect with prayer warriors near you';
  static const String searchCity = 'Search for your city...';
  static const String locationSelected = 'Location selected';

  // Navigation
  static const String back = 'Back';
  static const String next = 'Next';
  static const String finish = 'Finish';
  static const String skip = 'Skip';

  // ============================================================================
  // Email Verification
  // ============================================================================
  static const String verifyYourEmail = 'Verify your email';
  static const String toJoinCommunity = 'to join the community';
  static const String resend = 'Resend';
  static const String sent = 'Sent!';
  static const String verificationEmailSent = 'Verification email sent! Check your inbox.';

  // ============================================================================
  // Profile
  // ============================================================================
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String editBio = 'Edit Bio';
  static const String saveBio = 'Save Bio';
  static const String bioUpdated = 'Bio updated successfully';
  static const String shareProfile = 'Share Profile';
  static const String locationNotSet = 'Location not set';
  static const String prayers = 'Prayers';
  static const String answered = 'Answered';
  static const String dayStreak = 'Day Streak';

  // Settings
  static const String notifications = 'Notifications';
  static const String manageReminders = 'Manage reminders';
  static const String privacySecurity = 'Privacy & Security';
  static const String accountProtection = 'Account protection';
  static const String helpSupport = 'Help & Support';
  static const String faqsContact = 'FAQs and contact';
  static const String aboutKneel = 'About Kneel';
  static const String signOut = 'Sign Out';
  static const String signOutConfirm = 'Are you sure you want to sign out?';
  static const String cancel = 'Cancel';

  // ============================================================================
  // Home
  // ============================================================================
  static const String today = 'Today';
  static const String community = 'Community';
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';

  // ============================================================================
  // Errors
  // ============================================================================
  static const String somethingWentWrong = 'Something went wrong';
  static const String tryAgain = 'Try Again';
  static const String errorPrefix = 'Error:';
  static const String invalidPhoneNumber = 'Please enter your phone number';
  static const String invalidVerificationCode = 'Please enter the 6-digit code';
  static const String sessionExpired = 'Verification session expired. Please try again.';
  static const String bioCannotBeEmpty = 'Bio cannot be empty';

  // ============================================================================
  // Helpers
  // ============================================================================

  /// Formats step indicator text.
  static String formatStep(int current, int total) {
    return 'Step $current of $total';
  }

  /// Gets time-based greeting.
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return goodMorning;
    if (hour < 17) return goodAfternoon;
    return goodEvening;
  }

  /// Formats greeting with name.
  static String greetingWithName(String name) {
    return '${getGreeting()}, $name';
  }
}
