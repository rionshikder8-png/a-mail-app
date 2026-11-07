import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  bool _online = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isOnline => _online;

  Future<void> start() async {
    try {
      _apply(await Connectivity().checkConnectivity());
      _sub ??= Connectivity().onConnectivityChanged.listen(_apply);
    } catch (_) {
      _online = true;
    }
  }

  void _apply(List<ConnectivityResult> r) {
    final next = r.any((e) => e != ConnectivityResult.none);
    if (next != _online) {
      _online = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
