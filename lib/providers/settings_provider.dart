import 'package:flutter/material.dart';
import '../core/config/api_config.dart';
import '../core/constants/storage_keys.dart';
import '../data/local/preferences_store.dart';

enum SwipeAction { archive, delete, none }

class SettingsProvider extends ChangeNotifier {
  final _p = PreferencesStore.instance;

  String signature = '';
  bool signatureEnabled = true;
  String language = 'en';
  SwipeAction swipeRight = SwipeAction.archive;
  SwipeAction swipeLeft = SwipeAction.delete;
  bool compactDensity = false;
  String apiBaseUrl = '';

  static const languages = {
    'en': 'English',
    'bn': 'বাংলা (Bengali)',
    'hi': 'हिन्दी (Hindi)',
    'ar': 'العربية (Arabic)',
    'es': 'Español',
    'fr': 'Français',
  };

  Future<void> load() async {
    signature = await _p.getString(StorageKeys.signature) ?? '';
    signatureEnabled = await _p.getBool('${StorageKeys.signature}.enabled', def: true);
    language = await _p.getString(StorageKeys.language) ?? 'en';
    swipeRight = _action(await _p.getString(StorageKeys.swipeRight), SwipeAction.archive);
    swipeLeft = _action(await _p.getString(StorageKeys.swipeLeft), SwipeAction.delete);
    compactDensity = await _p.getBool(StorageKeys.density);
    apiBaseUrl = await _p.getString(StorageKeys.apiBaseUrl) ?? '';
    notifyListeners();
  }

  SwipeAction _action(String? v, SwipeAction d) =>
      SwipeAction.values.firstWhere((a) => a.name == v, orElse: () => d);

  Future<void> setSignature(String v, bool enabled) async {
    signature = v;
    signatureEnabled = enabled;
    await _p.setString(StorageKeys.signature, v);
    await _p.setBool('${StorageKeys.signature}.enabled', enabled);
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    language = v;
    await _p.setString(StorageKeys.language, v);
    notifyListeners();
  }

  Future<void> setSwipe({SwipeAction? right, SwipeAction? left}) async {
    if (right != null) {
      swipeRight = right;
      await _p.setString(StorageKeys.swipeRight, right.name);
    }
    if (left != null) {
      swipeLeft = left;
      await _p.setString(StorageKeys.swipeLeft, left.name);
    }
    notifyListeners();
  }

  Future<void> setDensity(bool compact) async {
    compactDensity = compact;
    await _p.setBool(StorageKeys.density, compact);
    notifyListeners();
  }

  Future<void> setApiBaseUrl(String v) async {
    apiBaseUrl = v.trim();
    ApiConfig.setRuntimeBaseUrl(apiBaseUrl);
    if (apiBaseUrl.isEmpty) {
      await _p.remove(StorageKeys.apiBaseUrl);
    } else {
      await _p.setString(StorageKeys.apiBaseUrl, apiBaseUrl);
    }
    notifyListeners();
  }
}
