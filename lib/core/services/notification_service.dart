import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notification surface + the hook where a push provider (FCM/APNs) token
/// will be registered once the backend exists. No push token is fabricated.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Set by a future push integration (FCM/APNs). Null until configured.
  String? pushToken;

  Future<void> init() async {
    if (_ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
          requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false);
      await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  Future<bool> requestPermission() async {
    await init();
    try {
      final a = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      final i = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return (a ?? i ?? false);
    } catch (_) {
      return false;
    }
  }

  Future<void> showNewMail({required String id, required String sender, required String subject}) async {
    if (!_ready) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails('new_mail', 'New mail',
          channelDescription: 'Notifications for new emails',
          importance: Importance.high,
          priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id.hashCode & 0x7fffffff, sender, subject, details);
  }
}
