import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/storage_keys.dart';
import '../core/network/api_response.dart';
import '../core/services/notification_service.dart';
import '../data/local/preferences_store.dart';
import '../data/repositories/misc_repository.dart';
import '../models/notification_model.dart';
import 'email_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final _repo = MiscRepository.instance;

  List<NotificationModel> items = [];
  LoadState state = LoadState.idle;
  ApiError? error;

  bool newMail = true;
  bool sound = true;
  bool securityAlerts = true;
  bool permissionGranted = false;

  int get unread => items.where((n) => !n.read).length;

  Future<void> loadPrefs() async {
    final raw = await PreferencesStore.instance.getString(StorageKeys.notifPrefs);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        newMail = m['new_mail'] ?? true;
        sound = m['sound'] ?? true;
        securityAlerts = m['security'] ?? true;
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> savePrefs({bool? newMail, bool? sound, bool? securityAlerts}) async {
    this.newMail = newMail ?? this.newMail;
    this.sound = sound ?? this.sound;
    this.securityAlerts = securityAlerts ?? this.securityAlerts;
    notifyListeners();
    final map = {'new_mail': this.newMail, 'sound': this.sound, 'security': this.securityAlerts};
    await PreferencesStore.instance.setString(StorageKeys.notifPrefs, jsonEncode(map));
    _repo.savePrefs(map); // best-effort sync; local value is source of truth offline
  }

  Future<bool> requestPermission() async {
    permissionGranted = await NotificationService.instance.requestPermission();
    notifyListeners();
    return permissionGranted;
  }

  Future<void> load({bool refresh = false}) async {
    if (state == LoadState.loading) return;
    state = LoadState.loading;
    notifyListeners();
    final r = await _repo.notifications();
    if (r.ok) {
      items = r.data ?? [];
      state = items.isEmpty ? LoadState.empty : LoadState.loaded;
    } else {
      error = r.error;
      state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final ids = items.where((n) => !n.read).map((n) => n.id).toList();
    if (ids.isEmpty) return;
    items = [for (final n in items) n.copyWith(read: true)];
    notifyListeners();
    await _repo.markNotificationsRead(ids);
  }
}
