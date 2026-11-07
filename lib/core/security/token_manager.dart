import '../constants/storage_keys.dart';
import 'secure_storage.dart';

class TokenManager {
  TokenManager._();
  static final TokenManager instance = TokenManager._();

  String? _access;
  String? _refresh;

  String? get accessToken => _access;
  String? get refreshToken => _refresh;
  bool get hasSession => _refresh != null && _refresh!.isNotEmpty;

  Future<void> load() async {
    _access = await SecureStore.instance.read(StorageKeys.accessToken);
    _refresh = await SecureStore.instance.read(StorageKeys.refreshToken);
  }

  Future<void> save({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
    await SecureStore.instance.write(StorageKeys.accessToken, access);
    await SecureStore.instance.write(StorageKeys.refreshToken, refresh);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    await SecureStore.instance.delete(StorageKeys.accessToken);
    await SecureStore.instance.delete(StorageKeys.refreshToken);
  }
}
