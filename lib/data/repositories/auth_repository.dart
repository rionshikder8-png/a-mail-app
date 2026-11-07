import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/network/api_response.dart';
import '../../core/security/token_manager.dart';
import '../../core/services/local_database.dart';
import '../../models/user_model.dart';
import '../datasources/remote_datasource.dart';

class AuthResult {
  final UserModel? user;
  final String? twoFactorChallengeId;
  final bool needsEmailVerification;
  const AuthResult({this.user, this.twoFactorChallengeId, this.needsEmailVerification = false});
}

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();
  final _remote = RemoteDataSource.instance;

  Future<ApiResponse<bool>> usernameAvailable(String u) => _remote.usernameAvailable(u);

  Future<ApiResponse<AuthResult>> register(
      {required String username, required String password, required String displayName, String? recoveryEmail}) async {
    final r = await _remote.register(
        username: username, password: password, displayName: displayName, recoveryEmail: recoveryEmail);
    if (!r.ok) return ApiResponse.failure(r.error!);
    return ApiResponse.success(await _completeSession(r.data!));
  }

  Future<ApiResponse<AuthResult>> login(String username, String password) async {
    final r = await _remote.login(username, password,
        deviceName: Platform.localHostname, platform: Platform.isIOS ? 'ios' : 'android');
    if (!r.ok) return ApiResponse.failure(r.error!);
    final d = r.data!;
    if (d['two_factor_required'] == true) {
      return ApiResponse.success(AuthResult(twoFactorChallengeId: '${d['challenge_id']}'));
    }
    return ApiResponse.success(await _completeSession(d));
  }

  Future<ApiResponse<AuthResult>> completeTwoFactor(String challengeId, String code) async {
    final r = await _remote.twoFactorLogin(challengeId, code);
    if (!r.ok) return ApiResponse.failure(r.error!);
    return ApiResponse.success(await _completeSession(r.data!));
  }

  Future<AuthResult> _completeSession(Map<String, dynamic> d) async {
    await TokenManager.instance.save(access: '${d['access_token']}', refresh: '${d['refresh_token']}');
    final user = UserModel.fromJson(Map<String, dynamic>.from(d['user'] as Map));
    await cacheUser(user);
    return AuthResult(user: user, needsEmailVerification: !user.emailVerified);
  }

  Future<UserModel?> restore() async {
    await TokenManager.instance.load();
    if (!TokenManager.instance.hasSession) return null;
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(StorageKeys.cachedUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheUser(UserModel u) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(StorageKeys.cachedUser, jsonEncode(u.toJson()));
  }

  Future<UserModel?> refreshProfile() async {
    final r = await _remote.profile();
    if (r.ok && r.data != null) {
      await cacheUser(r.data!);
      return r.data;
    }
    return null;
  }

  Future<void> signOut({bool notifyServer = true}) async {
    if (notifyServer && TokenManager.instance.hasSession) {
      await _remote.logout();
    }
    await TokenManager.instance.clear();
    final p = await SharedPreferences.getInstance();
    await p.remove(StorageKeys.cachedUser);
    await LocalDatabase.instance.wipe();
  }

  Future<ApiResponse<void>> forgotPassword(String id) => _remote.forgotPassword(id);
  Future<ApiResponse<void>> verifyOtp(String id, String code, String purpose) => _remote.verifyOtp(id, code, purpose);
  Future<ApiResponse<void>> verifyEmail(String code) => _remote.verifyEmail(code);
  Future<ApiResponse<void>> resendVerification() => _remote.resendVerification();
  Future<ApiResponse<void>> resetPassword(String id, String code, String pw) => _remote.resetPassword(id, code, pw);
}
