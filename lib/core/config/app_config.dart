class AppConfig {
  AppConfig._();

  static const String appName = 'A-Mail';
  static const String brand = 'Adverune';
  static const String fullName = 'A-Mail by Adverune';
  static const String tagline = 'Your Email. Your Identity.';
  static const String emailDomain = 'adverune.store';
  static const String supportAddress = 'support@adverune.store';

  /// Minimum / maximum rules shared with the future backend.
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 30;
  static const int passwordMinLength = 8;
  static const int otpLength = 6;
  static const int maxAttachmentBytes = 25 * 1024 * 1024;
  static const int pageSize = 25;
  static const Duration undoSendWindow = Duration(seconds: 5);
  static const Duration draftAutosave = Duration(seconds: 3);
}
