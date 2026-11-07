import 'package:flutter/material.dart';
import '../core/constants/storage_keys.dart';
import '../data/local/preferences_store.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final v = await PreferencesStore.instance.getString(StorageKeys.themeMode);
    _mode = ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    await PreferencesStore.instance.setString(StorageKeys.themeMode, m.name);
  }
}
