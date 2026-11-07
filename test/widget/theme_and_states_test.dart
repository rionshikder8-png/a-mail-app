import 'package:a_mail/core/network/api_response.dart';
import 'package:a_mail/core/theme/app_theme.dart';
import 'package:a_mail/models/attachment_model.dart';
import 'package:a_mail/models/email_model.dart';
import 'package:a_mail/providers/theme_provider.dart';
import 'package:a_mail/screens/inbox/email_tile.dart';
import 'package:a_mail/shared/widgets/otp_field.dart';
import 'package:a_mail/shared/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(Widget child, {ThemeMode mode = ThemeMode.light}) => MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: Scaffold(body: child),
    );

EmailModel email({bool read = false, bool star = false, bool att = false, int thread = 1}) => EmailModel(
      id: '1',
      threadId: '1',
      from: const EmailAddress(name: 'Ann Lee', address: 'ann@x.com'),
      subject: 'Quarterly plan',
      snippet: 'Here is the plan',
      date: DateTime.now(),
      isRead: read,
      isStarred: star,
      threadCount: thread,
      attachments: att ? const [AttachmentModel(id: '1', fileName: 'a.pdf', mimeType: 'application/pdf', sizeBytes: 10)] : const [],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('light and dark themes render with distinct surfaces', (t) async {
    await t.pumpWidget(host(const Text('x')));
    final light = Theme.of(t.element(find.text('x')));
    await t.pumpWidget(host(const Text('x'), mode: ThemeMode.dark));
    await t.pumpAndSettle();
    final dark = Theme.of(t.element(find.text('x')));
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.colorScheme.surface, isNot(dark.colorScheme.surface));
  });

  testWidgets('ThemeProvider switches mode and persists', (t) async {
    final p = ThemeProvider();
    await p.setMode(ThemeMode.dark);
    expect(p.mode, ThemeMode.dark);
    final p2 = ThemeProvider();
    await p2.load();
    expect(p2.mode, ThemeMode.dark);
  });

  testWidgets('EmailTile shows unread styling, thread count, star, attachment', (t) async {
    var starred = 0;
    await t.pumpWidget(host(EmailTile(
      email: email(thread: 3, att: true),
      selected: false,
      selectionMode: false,
      onTap: () {},
      onLongPress: () {},
      onAvatarTap: () {},
      onToggleStar: () => starred++,
    )));
    expect(find.text('Quarterly plan'), findsOneWidget);
    expect(find.textContaining('Ann Lee'), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets);
    expect(find.byIcon(Icons.attach_file_rounded), findsOneWidget);
    final subject = t.widget<Text>(find.text('Quarterly plan'));
    expect(subject.style?.fontWeight, FontWeight.w700); // unread = bold
    await t.tap(find.byIcon(Icons.star_outline_rounded));
    expect(starred, 1);
  });

  testWidgets('EmailTile read state is not bold; selected shows check', (t) async {
    await t.pumpWidget(host(EmailTile(
      email: email(read: true),
      selected: true,
      selectionMode: true,
      onTap: () {},
      onLongPress: () {},
      onAvatarTap: () {},
      onToggleStar: () {},
    )));
    await t.pumpAndSettle();
    expect(t.widget<Text>(find.text('Quarterly plan')).style?.fontWeight, FontWeight.w400);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('StateView.error picks copy per error type', (t) async {
    await t.pumpWidget(host(StateView.error(const ApiError(code: 'backend_unavailable', message: 'x'))));
    expect(find.text('Server not connected'), findsOneWidget);
    await t.pumpWidget(host(StateView.error(const ApiError(code: 'offline', message: 'No net'))));
    expect(find.text('You\'re offline'), findsOneWidget);
    var retried = false;
    await t.pumpWidget(host(StateView.error(const ApiError(code: 'x', message: 'Boom'), onRetry: () => retried = true)));
    await t.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('Empty state renders title and message', (t) async {
    await t.pumpWidget(host(StateView.empty(icon: Icons.inbox_rounded, title: 'Nothing here', message: 'Msg')));
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Msg'), findsOneWidget);
  });

  testWidgets('OtpField reports typed digits and completion', (t) async {
    String last = '';
    String? done;
    await t.pumpWidget(host(OtpField(onChanged: (v) => last = v, onCompleted: (v) => done = v)));
    await t.enterText(find.byType(TextField), '123456');
    await t.pump();
    expect(last, '123456');
    expect(done, '123456');
  });

  testWidgets('responsive: skeleton + offline banner build on small and wide screens', (t) async {
    for (final size in [const Size(360, 640), const Size(900, 1200)]) {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      await t.pumpWidget(host(const Column(children: [OfflineBanner(), SizedBox(height: 300, child: ListSkeleton(count: 3))])));
      expect(tester(t), isNull);
    }
    addTearDown(t.view.reset);
  });
}

Object? tester(WidgetTester t) => t.takeException();
