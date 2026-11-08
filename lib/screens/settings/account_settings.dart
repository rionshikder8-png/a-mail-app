import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/repositories/misc_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/email_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/components/settings_tiles.dart';
import '../../shared/dialogs/dialogs.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Account management')),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        SettingsSection(title: 'Account', children: [
          SettingsTile(icon: Icons.alternate_email_rounded, title: 'Address', subtitle: auth.user?.address),
          SettingsTile(icon: Icons.verified_outlined, title: 'Verification', subtitle: (auth.user?.emailVerified ?? false) ? 'Verified' : 'Not verified'),
        ]),
        SettingsSection(title: 'Server', children: [
          SettingsTile(
            icon: Icons.dns_outlined,
            title: 'API server address',
            subtitle: ApiConfig.isExplicitlyConfigured ? ApiConfig.baseUrl : '${ApiConfig.proposedBaseUrl} (default)',
            onTap: () async {
              final v = await promptDialog(context, title: 'API server address', initial: s.apiBaseUrl, hint: ApiConfig.proposedBaseUrl);
              if (v == null) return;
              if (v.isNotEmpty && !(v.startsWith('https://') || v.startsWith('http://'))) {
                if (context.mounted) context.toast('Address must start with https:// or http://', error: true);
                return;
              }
              await s.setApiBaseUrl(v);
              if (context.mounted) {
                context.read<EmailProvider>().reset();
                context.toast(v.isEmpty ? 'Reset to default' : 'Server address saved');
              }
            },
          ),
          SettingsTile(
            icon: Icons.network_check_rounded,
            title: 'Test connection',
            subtitle: 'Check that the A-Mail server answers',
            onTap: () async {
              context.toast('Contacting ${ApiConfig.baseUrl}...');
              final r = await ApiClient.instance.get<Map<String, dynamic>>(
                ApiEndpoints.health,
                auth: false,
                parse: (d) => Map<String, dynamic>.from(d as Map),
              );
              if (!context.mounted) return;
              if (r.ok) {
                final v = r.data?['version'] ?? '';
                context.toast('Connected to A-Mail server${v == '' ? '' : ' v$v'}');
              } else {
                context.toast(r.error?.isOffline == true ? 'You are offline' : 'Cannot reach the server: ${r.error?.message ?? 'unknown error'}', error: true);
              }
            },
          ),
        ]),
        SettingsSection(title: 'Danger zone', children: [
          SettingsTile(
            icon: Icons.delete_forever_outlined,
            iconColor: context.colors.error,
            title: 'Delete account',
            subtitle: 'Permanently delete your address and all mail',
            onTap: () async {
              final pw = await promptDialog(context, title: 'Confirm with password', hint: 'Password', confirmLabel: 'Delete account', obscure: true);
              if (pw == null || pw.isEmpty || !context.mounted) return;
              final ok = await confirmDialog(context,
                  title: 'Delete account permanently?', message: 'This cannot be undone. Your address and all messages will be erased.', confirmLabel: 'Delete', destructive: true);
              if (!ok || !context.mounted) return;
              final r = await MiscRepository.instance.deleteAccount(pw);
              if (!context.mounted) return;
              if (r.ok) {
                context.read<EmailProvider>().reset();
                await context.read<AuthProvider>().signOut(notifyServer: false);
              } else {
                context.toast(r.error!.message, error: true);
              }
            },
          ),
        ]),
      ]),
    );
  }
}
