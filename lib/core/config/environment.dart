enum AppEnvironment { development, staging, production }

/// Resolved at build time via `--dart-define=A_MAIL_ENV=production`.
class Environment {
  Environment._();

  static const String _raw =
      String.fromEnvironment('A_MAIL_ENV', defaultValue: 'development');

  static AppEnvironment get current {
    switch (_raw) {
      case 'production':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.development;
    }
  }

  static bool get isProduction => current == AppEnvironment.production;
}
