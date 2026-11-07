import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/contact_model.dart';
import '../models/email_model.dart';
import '../models/attachment_model.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/recovery_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/verify_otp_screen.dart';
import '../screens/contacts/contact_details_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/email/attachment_viewer.dart';
import '../screens/email/compose_screen.dart';
import '../screens/email/email_view_screen.dart';
import '../screens/email/forward_screen.dart';
import '../screens/email/reply_screen.dart';
import '../screens/folders/folder_screen_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/labels/label_details_screen.dart';
import '../screens/labels/labels_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/premium/plans_screen.dart';
import '../screens/premium/subscription_screen.dart';
import '../screens/search/advanced_search_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/account_settings.dart';
import '../screens/settings/appearance_screen.dart';
import '../screens/settings/devices_screen.dart';
import '../screens/settings/notification_settings.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/security_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/signature_screen.dart';
import '../screens/settings/storage_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/storage/storage_manager_screen.dart';
import 'route_names.dart';

class ComposeArgs {
  final EmailModel? original;
  final List<EmailAddress>? to;
  final EmailModel? draft;
  const ComposeArgs({this.original, this.to, this.draft});
}

class AppRouter {
  AppRouter._();

  static const _publicPaths = {
    Routes.splash,
    Routes.onboarding,
    Routes.welcome,
    Routes.login,
    Routes.register,
    Routes.forgot,
    Routes.verifyOtp,
    Routes.recovery,
  };

  /// Pure redirect rules (kept separate so they can be unit-tested).
  static String? redirectFor(AuthProvider auth, String path) {
    if (auth.status == AuthStatus.unknown) return path == Routes.splash ? null : Routes.splash;
    final signedIn = auth.status == AuthStatus.signedIn;
    if (path == Routes.splash) return null; // splash decides after its animation
    if (!signedIn && !_publicPaths.contains(path)) {
      return auth.onboardingDone ? Routes.welcome : Routes.onboarding;
    }
    if (signedIn && _publicPaths.contains(path) && path != Routes.verifyOtp && path != Routes.recovery) {
      return Routes.home;
    }
    return null;
  }

  static GoRouter build(AuthProvider auth) {
    return GoRouter(
      initialLocation: Routes.splash,
      refreshListenable: auth,
      redirect: (context, state) => redirectFor(auth, state.matchedLocation),
      routes: [
        GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: Routes.welcome, builder: (_, __) => const WelcomeScreen()),
        GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
        GoRoute(path: Routes.forgot, builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(
          path: Routes.verifyOtp,
          builder: (_, s) => VerifyOtpScreen(args: s.extra as OtpArgs),
        ),
        GoRoute(path: Routes.verifyEmail, builder: (_, __) => const VerifyEmailScreen()),
        GoRoute(path: Routes.recovery, builder: (_, __) => const RecoveryScreen()),
        GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen()),
        GoRoute(path: Routes.folder, builder: (_, s) => FolderScreenRouter(folderId: s.pathParameters['id']!)),
        GoRoute(
          path: Routes.label,
          builder: (_, s) => LabelDetailsScreen(labelId: s.pathParameters['id']!, name: (s.extra as String?) ?? 'Label'),
        ),
        GoRoute(
          path: Routes.thread,
          builder: (_, s) => EmailViewScreen(emailId: s.pathParameters['id']!, initial: s.extra as EmailModel?),
        ),
        GoRoute(path: Routes.compose, builder: (_, s) {
          final x = s.extra;
          if (x is EmailModel) return ComposeScreen(draft: x);
          final a = x as ComposeArgs?;
          return ComposeScreen(prefilledTo: a?.to, draft: a?.draft);
        }),
        GoRoute(path: Routes.reply, builder: (_, s) {
          final a = s.extra as ReplyArgs;
          return ReplyScreen(original: a.original, replyAll: a.replyAll);
        }),
        GoRoute(path: Routes.forward, builder: (_, s) => ForwardScreen(original: s.extra as EmailModel)),
        GoRoute(path: Routes.search, builder: (_, __) => const SearchScreen()),
        GoRoute(path: Routes.advancedSearch, builder: (_, __) => const AdvancedSearchScreen()),
        GoRoute(path: Routes.labels, builder: (_, __) => const LabelsScreen()),
        GoRoute(path: Routes.contacts, builder: (_, s) => ContactsScreen(pickMode: s.extra == 'pick')),
        GoRoute(path: Routes.contactDetails, builder: (_, s) => ContactDetailsScreen(contact: s.extra as ContactModel?)),
        GoRoute(path: Routes.notifications, builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: Routes.settings, builder: (_, __) => const SettingsScreen()),
        GoRoute(path: Routes.profile, builder: (_, __) => const ProfileScreen()),
        GoRoute(path: Routes.security, builder: (_, __) => const SecurityScreen()),
        GoRoute(path: Routes.devices, builder: (_, __) => const DevicesScreen()),
        GoRoute(path: Routes.signature, builder: (_, __) => const SignatureScreen()),
        GoRoute(path: Routes.appearance, builder: (_, __) => const AppearanceScreen()),
        GoRoute(path: Routes.notificationSettings, builder: (_, __) => const NotificationSettingsScreen()),
        GoRoute(path: Routes.storageSettings, builder: (_, __) => const StorageScreen()),
        GoRoute(path: Routes.account, builder: (_, __) => const AccountSettingsScreen()),
        GoRoute(path: Routes.storageManager, builder: (_, __) => const StorageManagerScreen()),
        GoRoute(path: Routes.plans, builder: (_, __) => const PlansScreen()),
        GoRoute(path: Routes.subscription, builder: (_, __) => const SubscriptionScreen()),
        GoRoute(path: Routes.attachment, builder: (_, s) => AttachmentViewer(attachment: s.extra as AttachmentModel)),
      ],
      errorBuilder: (_, s) => Scaffold(body: Center(child: Text('Page not found\n${s.uri}', textAlign: TextAlign.center))),
    );
  }
}
