import 'package:a_mail/navigation/app_router.dart';
import 'package:a_mail/navigation/route_names.dart';
import 'package:a_mail/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends AuthProvider {
  _FakeAuth(AuthStatus s, {bool onboarded = false}) {
    status = s;
    onboardingDone = onboarded;
  }
}

/// Follows redirects until stable, like go_router does.
String land(AuthProvider auth, String target) {
  var path = target;
  for (var i = 0; i < 5; i++) {
    final next = AppRouter.redirectFor(auth, path);
    if (next == null) return path;
    path = next;
  }
  return path;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('unknown auth forces splash', () {
    expect(land(_FakeAuth(AuthStatus.unknown), Routes.home), Routes.splash);
  });

  test('signed-out user is sent to onboarding first, then welcome', () {
    expect(land(_FakeAuth(AuthStatus.signedOut), Routes.home), Routes.onboarding);
    expect(land(_FakeAuth(AuthStatus.signedOut, onboarded: true), Routes.home), Routes.welcome);
  });

  test('signed-out user may open public auth routes', () {
    expect(land(_FakeAuth(AuthStatus.signedOut, onboarded: true), Routes.login), Routes.login);
    expect(land(_FakeAuth(AuthStatus.signedOut, onboarded: true), Routes.register), Routes.register);
    expect(land(_FakeAuth(AuthStatus.signedOut, onboarded: true), Routes.forgot), Routes.forgot);
  });

  test('signed-in user is bounced from auth screens to home', () {
    expect(land(_FakeAuth(AuthStatus.signedIn), Routes.login), Routes.home);
    expect(land(_FakeAuth(AuthStatus.signedIn), Routes.welcome), Routes.home);
  });

  test('protected routes are blocked when signed out', () {
    for (final p in [Routes.settings, Routes.compose, Routes.search, Routes.labels]) {
      expect(land(_FakeAuth(AuthStatus.signedOut, onboarded: true), p), Routes.welcome, reason: p);
    }
  });

  test('every route constant is unique', () {
    final all = [
      Routes.splash, Routes.onboarding, Routes.welcome, Routes.login, Routes.register, Routes.forgot,
      Routes.verifyOtp, Routes.verifyEmail, Routes.recovery, Routes.home, Routes.search, Routes.advancedSearch,
      Routes.labels, Routes.contacts, Routes.notifications, Routes.settings, Routes.plans, Routes.compose,
    ];
    expect(all.toSet().length, all.length);
    expect(GoRouter, isNotNull);
  });
}
