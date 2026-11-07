import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/app_lock_screen.dart';

class AMailApp extends StatefulWidget {
  const AMailApp({super.key});
  @override
  State<AMailApp> createState() => _AMailAppState();
}

class _AMailAppState extends State<AMailApp> {
  late final _router = AppRouter.build(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    return MaterialApp.router(
      title: AppConfig.fullName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.mode,
      routerConfig: _router,
      locale: Locale(settings.language),
      supportedLocales: const [Locale('en'), Locale('bn'), Locale('hi'), Locale('ar'), Locale('es'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final auth = context.watch<AuthProvider>();
        return Stack(children: [
          child ?? const SizedBox.shrink(),
          if (auth.status == AuthStatus.signedIn && auth.locked) const AppLockScreen(),
        ]);
      },
    );
  }
}
