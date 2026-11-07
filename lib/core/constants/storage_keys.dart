class StorageKeys {
  StorageKeys._();

  // Secure storage (secrets only)
  static const accessToken = 'amail.access_token';
  static const refreshToken = 'amail.refresh_token';
  static const userId = 'amail.user_id';
  static const biometricEnabled = 'amail.biometric_enabled';

  // Shared preferences (non-sensitive)
  static const themeMode = 'amail.theme_mode';
  static const onboardingDone = 'amail.onboarding_done';
  static const apiBaseUrl = 'amail.api_base_url';
  static const cachedUser = 'amail.cached_user';
  static const signature = 'amail.signature';
  static const language = 'amail.language';
  static const notifPrefs = 'amail.notif_prefs';
  static const swipeRight = 'amail.swipe_right';
  static const swipeLeft = 'amail.swipe_left';
  static const density = 'amail.density';
}
