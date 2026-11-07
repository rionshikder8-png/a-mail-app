import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../navigation/route_names.dart';
import '../../shared/components/settings_tiles.dart';
import 'auth_scaffold.dart';

class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Account recovery',
      subtitle: 'Choose how you want to regain access to your A-Mail address.',
      child: Column(children: [
        SettingsSection(children: [
          SettingsTile(
            icon: Icons.password_rounded,
            title: 'Reset with a code',
            subtitle: 'We email a one-time code to your recovery address.',
            onTap: () => context.push(Routes.forgot),
          ),
          SettingsTile(
            icon: Icons.support_agent_rounded,
            title: 'Contact support',
            subtitle: AppConfig.supportAddress,
            trailing: const Icon(Icons.mail_outline_rounded, size: 20),
          ),
        ]),
        const SizedBox(height: 16),
        Text(
          'For your security, A-Mail support will never ask for your password or verification codes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ]),
    );
  }
}
