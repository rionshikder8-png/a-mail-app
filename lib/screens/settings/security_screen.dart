import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/security/biometric_service.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/misc_repository.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../shared/components/settings_tiles.dart';
import '../../shared/widgets/app_text_field.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    BiometricService.instance.isAvailable().then((v) => mounted ? setState(() => _bioAvailable = v) : null);
  }

  Future<void> _toggle2fa(bool v) async {
    final auth = context.read<AuthProvider>();
    final r = await MiscRepository.instance.setTwoFactor(v);
    if (!mounted) return;
    if (r.ok) {
      auth.updateUser(auth.user!.copyWith(twoFactorEnabled: v));
      context.toast(v ? 'Two-factor authentication enabled' : 'Two-factor authentication disabled');
    } else {
      context.toast(r.error!.message, error: true);
    }
  }

  Future<void> _changePassword() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _ChangePasswordSheet());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        SettingsSection(title: 'Sign-in', children: [
          SettingsTile(icon: Icons.password_rounded, title: 'Change password', onTap: _changePassword),
          SettingsSwitch(
            icon: Icons.verified_user_outlined,
            title: 'Two-factor authentication',
            subtitle: 'Require a code when signing in on a new device',
            value: auth.user?.twoFactorEnabled ?? false,
            onChanged: _toggle2fa,
          ),
        ]),
        SettingsSection(title: 'This device', children: [
          SettingsSwitch(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric unlock',
            subtitle: _bioAvailable ? 'Require fingerprint or face to open A-Mail' : 'Not available on this device',
            value: auth.biometricEnabled,
            onChanged: _bioAvailable ? auth.setBiometric : null,
          ),
        ]),
        SettingsSection(title: 'Activity', children: [
          SettingsTile(icon: Icons.devices_other_rounded, title: 'Devices & login history', onTap: () => context.push(Routes.devices)),
          SettingsTile(icon: Icons.mark_email_read_outlined, title: 'Recovery options', subtitle: auth.user?.recoveryEmail ?? 'Not set', onTap: () => context.push(Routes.profile)),
        ]),
      ]),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _conf = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    for (final c in [_cur, _new, _conf]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    final r = await MiscRepository.instance.changePassword(_cur.text, _new.text);
    if (!mounted) return;
    if (r.ok) {
      Navigator.pop(context);
      context.toast('Password changed');
    } else {
      setState(() {
        _busy = false;
        _err = r.error!.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Change password', style: context.text.titleLarge),
          const SizedBox(height: 16),
          if (_err != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_err!, style: TextStyle(color: context.colors.error))),
          AppTextField(controller: _cur, label: 'Current password', obscure: true, validator: (v) => Validators.required(v, 'Current password')),
          const SizedBox(height: 12),
          AppTextField(controller: _new, label: 'New password', obscure: true, validator: Validators.password),
          const SizedBox(height: 12),
          AppTextField(controller: _conf, label: 'Confirm new password', obscure: true, validator: (v) => v == _new.text ? null : 'Passwords don\'t match'),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : _save, child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Update password')),
        ]),
      ),
    );
  }
}
