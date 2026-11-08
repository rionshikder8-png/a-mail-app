import 'environment.dart';

/// API configuration. The default server is `https://api.adverune.store`; it can be
/// overridden at build time with `--dart-define=A_MAIL_API_URL=...` or changed at
/// runtime from Settings > Account > API server address (stored locally).
/// Use "Test connection" there to confirm the server is reachable.
class ApiConfig {
  ApiConfig._();

  static const String proposedBaseUrl = 'https://api.adverune.store';

  static const String _definedUrl =
      String.fromEnvironment('A_MAIL_API_URL', defaultValue: '');

  static String? _runtimeOverride;

  static void setRuntimeBaseUrl(String? url) {
    final v = url?.trim();
    _runtimeOverride = (v == null || v.isEmpty) ? null : v.replaceAll(RegExp(r'/+$'), '');
  }

  static String get baseUrl {
    if (_runtimeOverride != null) return _runtimeOverride!;
    if (_definedUrl.isNotEmpty) return _definedUrl;
    return proposedBaseUrl;
  }

  /// True only when a backend URL was explicitly configured by build or user.
  static bool get isExplicitlyConfigured =>
      _runtimeOverride != null || _definedUrl.isNotEmpty;

  static const String apiVersion = 'v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static String get apiRoot => '$baseUrl/$apiVersion';

  static bool get logRequests => !Environment.isProduction;
}
