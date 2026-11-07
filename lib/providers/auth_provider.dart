import 'package:flutter/material.dart';
import '../core/config/api_config.dart';
import '../core/constants/storage_keys.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../core/security/biometric_service.dart';
import '../core/security/secure_storage.dart';
import '../data/local/preferences_store.dart';
import '../data/repositories/auth_repository.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository.instance;

  AuthStatus status = AuthStatus.unknown;
  UserModel? user;
  bool busy = false;
  ApiError? error;
  bool onboardingDone = false;
  bool biometricEnabled = false;
  bool locked = false;
  String? pendingTwoFactorChallenge;

  AuthProvider() {
    ApiClient.instance.onSessionExpired = () {
      signOut(notifyServer: false);
    };
  }

  Future<void> bootstrap() async {
    final prefs = PreferencesStore.instance;
    onboardingDone = await prefs.getBool(StorageKeys.onboardingDone);
    biometricEnabled = await prefs.getBool(StorageKeys.biometricEnabled);
    final saved = await prefs.getString(StorageKeys.apiBaseUrl);
    ApiConfig.setRuntimeBaseUrl(saved);
    user = await _repo.restore();
    status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    locked = status == AuthStatus.signedIn && biometricEnabled;
    notifyListeners();
    if (user != null) {
      final fresh = await _repo.refreshProfile();
      if (fresh != null) {
        user = fresh;
        notifyListeners();
      }
    }
  }

  Future<void> completeOnboarding() async {
    onboardingDone = true;
    await PreferencesStore.instance.setBool(StorageKeys.onboardingDone, true);
    notifyListeners();
  }

  Future<bool> unlock() async {
    final ok = await BiometricService.instance.authenticate();
    if (ok) {
      locked = false;
      notifyListeners();
    }
    return ok;
  }

  Future<void> setBiometric(bool v) async {
    if (v && !await BiometricService.instance.authenticate(reason: 'Confirm to enable biometric unlock')) return;
    biometricEnabled = v;
    await PreferencesStore.instance.setBool(StorageKeys.biometricEnabled, v);
    notifyListeners();
  }

  Future<bool> checkUsername(String u) async {
    final r = await _repo.usernameAvailable(u);
    if (!r.ok) {
      error = r.error;
      notifyListeners();
      throw r.error!;
    }
    return r.data == true;
  }

  Future<AuthResult?> _run(Future<ApiResponse<AuthResult>> Function() f) async {
    busy = true;
    error = null;
    notifyListeners();
    final r = await f();
    busy = false;
    if (!r.ok) {
      error = r.error;
      notifyListeners();
      return null;
    }
    final res = r.data!;
    if (res.twoFactorChallengeId != null) {
      pendingTwoFactorChallenge = res.twoFactorChallengeId;
    } else if (res.user != null) {
      user = res.user;
      status = AuthStatus.signedIn;
      locked = false;
    }
    notifyListeners();
    return res;
  }

  Future<AuthResult?> login(String username, String password) => _run(() => _repo.login(username, password));

  Future<AuthResult?> register({
    required String username,
    required String password,
    required String displayName,
    String? recoveryEmail,
  }) =>
      _run(() => _repo.register(
          username: username, password: password, displayName: displayName, recoveryEmail: recoveryEmail));

  Future<AuthResult?> submitTwoFactor(String code) =>
      _run(() => _repo.completeTwoFactor(pendingTwoFactorChallenge ?? '', code));

  Future<ApiResponse<void>> forgotPassword(String id) => _repo.forgotPassword(id);
  Future<ApiResponse<void>> verifyOtp(String id, String code, String purpose) => _repo.verifyOtp(id, code, purpose);
  Future<ApiResponse<void>> verifyEmail(String code) async {
    final r = await _repo.verifyEmail(code);
    if (r.ok && user != null) {
      user = user!.copyWith(emailVerified: true);
      await _repo.cacheUser(user!);
      notifyListeners();
    }
    return r;
  }

  Future<ApiResponse<void>> resendVerification() => _repo.resendVerification();
  Future<ApiResponse<void>> resetPassword(String id, String code, String pw) => _repo.resetPassword(id, code, pw);

  void updateUser(UserModel u) {
    user = u;
    _repo.cacheUser(u);
    notifyListeners();
  }

  Future<void> signOut({bool notifyServer = true}) async {
    await _repo.signOut(notifyServer: notifyServer);
    await SecureStore.instance.delete(StorageKeys.userId);
    user = null;
    status = AuthStatus.signedOut;
    locked = false;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
