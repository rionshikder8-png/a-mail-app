import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../providers/notification_provider.dart';
import '../../shared/components/settings_tiles.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        SettingsSection(title: 'Permission', children: [
          SettingsTile(
            icon: p.permissionGranted ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
            title: p.permissionGranted ? 'Notifications allowed' : 'Allow notifications',
            subtitle: p.permissionGranted ? 'This device can show A-Mail alerts' : 'Tap to grant permission',
            onTap: p.permissionGranted
                ? null
                : () async {
                    final ok = await p.requestPermission();
                    if (context.mounted && !ok) context.toast('Permission denied. You can enable it in system settings.', error: true);
                  },
          ),
        ]),
        SettingsSection(title: 'Alerts', children: [
          SettingsSwitch(icon: Icons.mail_outline_rounded, title: 'New mail', subtitle: 'Notify me when a message arrives', value: p.newMail, onChanged: (v) => p.savePrefs(newMail: v)),
          SettingsSwitch(icon: Icons.volume_up_outlined, title: 'Sound', value: p.sound, onChanged: p.newMail ? (v) => p.savePrefs(sound: v) : null),
          SettingsSwitch(icon: Icons.shield_outlined, title: 'Security alerts', subtitle: 'New sign-ins and account changes', value: p.securityAlerts, onChanged: (v) => p.savePrefs(securityAlerts: v)),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text(
            'Push delivery to this device requires the A-Mail server. Preferences are saved on this device and synced when connected.',
            style: context.text.bodySmall,
          ),
        ),
      ]),
    );
  }
}
