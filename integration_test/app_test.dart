import 'package:a_mail/app.dart';
import 'package:a_mail/providers/auth_provider.dart';
import 'package:a_mail/providers/email_provider.dart';
import 'package:a_mail/providers/inbox_provider.dart';
import 'package:a_mail/providers/notification_provider.dart';
import 'package:a_mail/providers/settings_provider.dart';
import 'package:a_mail/providers/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start with no session lands on onboarding (no fake inbox)', (tester) async {
    final auth = AuthProvider();
    await auth.bootstrap();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => EmailProvider()),
        ChangeNotifierProvider(create: (_) => InboxProvider()),
      ],
      child: const AMailApp(),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
    expect(find.text('Inbox'), findsNothing);
  });
}
