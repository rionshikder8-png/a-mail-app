import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/network/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/sync_service.dart';
import 'providers/auth_provider.dart';
import 'providers/email_provider.dart';
import 'providers/inbox_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConnectivityService.instance.start();
  await NotificationService.instance.init();
  SyncService.instance.start();

  final theme = ThemeProvider();
  final settings = SettingsProvider();
  final notif = NotificationProvider();
  final auth = AuthProvider();
  await Future.wait([theme.load(), settings.load(), notif.loadPrefs(), auth.bootstrap()]);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: theme),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: notif),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => EmailProvider()),
      ChangeNotifierProvider(create: (_) => InboxProvider()),
      ChangeNotifierProvider.value(value: ConnectivityService.instance),
    ],
    child: const AMailApp(),
  ));
}
