import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import 'local_database.dart';

/// Replays queued actions (outbox) when connectivity returns.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  bool _running = false;
  VoidCallback? _listener;

  static const _endpoints = <String, String>{
    'send': ApiEndpoints.sendEmail,
    'archive': ApiEndpoints.archive,
    'delete': ApiEndpoints.delete,
    'star': ApiEndpoints.star,
    'mark_read': ApiEndpoints.markRead,
  };

  void start() {
    _listener ??= () {
      if (ConnectivityService.instance.isOnline) flush();
    };
    ConnectivityService.instance.addListener(_listener!);
  }

  Future<void> queue(String kind, Map<String, dynamic> payload) =>
      LocalDatabase.instance.enqueue(kind, payload);

  Future<int> pendingCount() async => (await LocalDatabase.instance.pendingOutbox()).length;

  Future<void> flush() async {
    if (_running) return;
    _running = true;
    try {
      for (final row in await LocalDatabase.instance.pendingOutbox()) {
        final path = _endpoints[row['kind']];
        if (path == null) {
          await LocalDatabase.instance.removeOutbox(row['id'] as int);
          continue;
        }
        final res = await ApiClient.instance
            .post<dynamic>(path, body: jsonDecode(row['payload'] as String));
        if (res.ok || (res.error?.statusCode != null && res.error!.statusCode! >= 400 && res.error!.statusCode! < 500 && res.error!.statusCode != 401)) {
          await LocalDatabase.instance.removeOutbox(row['id'] as int);
        } else {
          break; // still offline / server problem: retry later
        }
      }
    } finally {
      _running = false;
    }
  }
}
