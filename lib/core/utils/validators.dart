import '../config/app_config.dart';

class Validators {
  Validators._();

  static final _userRe = RegExp(r'^[a-z0-9](?:[a-z0-9._-]*[a-z0-9])?$');
  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? username(String? v) {
    final s = (v ?? '').trim().toLowerCase();
    if (s.isEmpty) return 'Choose a username';
    if (s.length < AppConfig.usernameMinLength) return 'At least ${AppConfig.usernameMinLength} characters';
    if (s.length > AppConfig.usernameMaxLength) return 'At most ${AppConfig.usernameMaxLength} characters';
    if (!_userRe.hasMatch(s)) return 'Use letters, numbers, dots, dashes or underscores';
    if (s.contains('..')) return 'No consecutive dots';
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Enter a password';
    if (s.length < AppConfig.passwordMinLength) return 'At least ${AppConfig.passwordMinLength} characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) return 'Include letters and numbers';
    return null;
  }

  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static bool isEmail(String v) => _emailRe.hasMatch(v.trim());

  static String? email(String? v, {bool optional = false}) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return optional ? null : 'Enter an email address';
    return isEmail(s) ? null : 'Enter a valid email address';
  }

  static String? otp(String? v) =>
      (v ?? '').trim().length == AppConfig.otpLength ? null : 'Enter the ${AppConfig.otpLength}-digit code';

  /// 0..4
  static int passwordStrength(String s) {
    var n = 0;
    if (s.length >= 8) n++;
    if (s.length >= 12) n++;
    if (RegExp(r'[A-Z]').hasMatch(s) && RegExp(r'[a-z]').hasMatch(s)) n++;
    if (RegExp(r'\d').hasMatch(s) && RegExp(r'[^A-Za-z0-9]').hasMatch(s)) n++;
    return n;
  }
}
