import 'package:shared_preferences/shared_preferences.dart';

/// Typed access to non-sensitive settings.
class PreferencesStore {
  PreferencesStore._();
  static final PreferencesStore instance = PreferencesStore._();
  SharedPreferences? _p;

  Future<SharedPreferences> get prefs async => _p ??= await SharedPreferences.getInstance();

  Future<String?> getString(String k) async => (await prefs).getString(k);
  Future<void> setString(String k, String v) async => (await prefs).setString(k, v);
  Future<bool> getBool(String k, {bool def = false}) async => (await prefs).getBool(k) ?? def;
  Future<void> setBool(String k, bool v) async => (await prefs).setBool(k, v);
  Future<void> remove(String k) async => (await prefs).remove(k);
}
