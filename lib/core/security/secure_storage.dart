import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper over the platform keystore (Android Keystore / iOS Keychain).
/// Only secrets (tokens) live here.
class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  static const _s = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<String?> read(String key) async {
    try {
      return await _s.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, String value) => _s.write(key: key, value: value);
  Future<void> delete(String key) => _s.delete(key: key);
  Future<void> clear() => _s.deleteAll();
}
