import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/extensions/context_extensions.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/email_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/components/settings_tiles.dart';
import '../../shared/dialogs/dialogs.dart';
import '../../shared/widgets/sender_avatar.dart';

class SettingsScreen extends StatelessWidget {
  final bool embedded;
  const SettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final settings = context.watch<SettingsProvider>();
    final cs = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), automaticallyImplyLeading: !embedded),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        InkWell(
          onTap: () => context.push(Routes.profile),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(children: [
              SenderAvatar(name: user?.displayName ?? '', seed: user?.username, size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.displayName ?? '', style: context.text.titleMedium),
                  Text(user?.address ?? '', style: context.text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text('${(user?.plan ?? 'free').toUpperCase()} PLAN', style: context.text.labelSmall?.copyWith(color: cs.primary)),
                  ),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ),
        SettingsSection(title: 'Account', children: [
          SettingsTile(icon: Icons.person_outline_rounded, title: 'Profile', subtitle: 'Name, photo, recovery options', onTap: () => context.push(Routes.profile)),
          SettingsTile(icon: Icons.shield_outlined, title: 'Security', subtitle: 'Password, two-factor, biometric unlock', onTap: () => context.push(Routes.security)),
          SettingsTile(icon: Icons.devices_other_rounded, title: 'Devices & login history', onTap: () => context.push(Routes.devices)),
          SettingsTile(icon: Icons.manage_accounts_outlined, title: 'Account management', onTap: () => context.push(Routes.account)),
        ]),
        SettingsSection(title: 'Mail', children: [
          SettingsTile(icon: Icons.draw_outlined, title: 'Signature', subtitle: settings.signature.isEmpty ? 'Not set' : settings.signature.split('\n').first, onTap: () => context.push(Routes.signature)),
          SettingsTile(icon: Icons.label_outline_rounded, title: 'Labels', onTap: () => context.push(Routes.labels)),
          SettingsTile(icon: Icons.contacts_outlined, title: 'Contacts', onTap: () => context.push(Routes.contacts)),
        ]),
        SettingsSection(title: 'App', children: [
          SettingsTile(icon: Icons.palette_outlined, title: 'Appearance', subtitle: 'Theme, density, swipe actions', onTap: () => context.push(Routes.appearance)),
          SettingsTile(icon: Icons.translate_rounded, title: 'Language', subtitle: SettingsProvider.languages[settings.language], onTap: () => _language(context)),
          SettingsTile(icon: Icons.notifications_none_rounded, title: 'Notifications', onTap: () => context.push(Routes.notificationSettings)),
          SettingsTile(icon: Icons.cloud_outlined, title: 'Storage', onTap: () => context.push(Routes.storageSettings)),
          SettingsTile(icon: Icons.workspace_premium_outlined, title: 'Plans & subscription', onTap: () => context.push(Routes.plans)),
        ]),
        SettingsSection(title: 'About', children: [
          SettingsTile(icon: Icons.info_outline_rounded, title: AppConfig.fullName, subtitle: 'Version 1.0.0 · ${AppConfig.tagline}'),
          SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: cs.error,
            title: 'Sign out',
            onTap: () async {
              if (await confirmDialog(context, title: 'Sign out?', message: 'Cached mail on this device will be removed.', confirmLabel: 'Sign out', destructive: true)) {
                if (!context.mounted) return;
                context.read<EmailProvider>().reset();
                await context.read<AuthProvider>().signOut();
              }
            },
          ),
        ]),
      ]),
    );
  }

  Future<void> _language(BuildContext context) async {
    final s = context.read<SettingsProvider>();
    final pick = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: RadioGroup<String>(
          groupValue: s.language,
          onChanged: (v) => Navigator.pop(c, v),
          child: ListView(shrinkWrap: true, children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('Language', style: Theme.of(c).textTheme.titleMedium)),
            for (final e in SettingsProvider.languages.entries) RadioListTile<String>(value: e.key, title: Text(e.value)),
          ]),
        ),
      ),
    );
    if (pick != null) {
      await s.setLanguage(pick);
      if (context.mounted) context.toast('Language set. Full translations are coming soon; dates and system dialogs follow your choice.');
    }
  }
}
