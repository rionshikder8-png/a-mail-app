import 'package:a_mail/core/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => ApiConfig.setRuntimeBaseUrl(null));

  test('defaults to the proposed host but is NOT marked configured', () {
    expect(ApiConfig.baseUrl, 'https://api.adverune.store');
    expect(ApiConfig.isExplicitlyConfigured, isFalse);
  });

  test('runtime override wins and strips trailing slash', () {
    ApiConfig.setRuntimeBaseUrl('https://mail.example.com///');
    expect(ApiConfig.baseUrl, 'https://mail.example.com');
    expect(ApiConfig.isExplicitlyConfigured, isTrue);
    expect(ApiConfig.apiRoot, 'https://mail.example.com/v1');
  });

  test('empty override resets', () {
    ApiConfig.setRuntimeBaseUrl('https://x.io');
    ApiConfig.setRuntimeBaseUrl('  ');
    expect(ApiConfig.isExplicitlyConfigured, isFalse);
  });
}
