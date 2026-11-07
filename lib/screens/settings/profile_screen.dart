import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/misc_repository.dart';
import '../../providers/auth_provider.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/sender_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<AuthProvider>().user?.displayName);
  late final _recEmail = TextEditingController(text: context.read<AuthProvider>().user?.recoveryEmail);
  late final _recPhone = TextEditingController(text: context.read<AuthProvider>().user?.recoveryPhone);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _recEmail.dispose();
    _recPhone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final r = await MiscRepository.instance.updateProfile({
      'display_name': _name.text.trim(),
      'recovery_email': _recEmail.text.trim(),
      'recovery_phone': _recPhone.text.trim(),
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok && r.data != null) {
      context.read<AuthProvider>().updateUser(r.data!);
      context.toast('Profile updated');
    } else {
      context.toast(r.error!.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Center(child: SenderAvatar(name: _name.text, seed: user?.username, size: 92)),
          const SizedBox(height: 8),
          Center(child: Text(user?.address ?? '', style: context.text.bodyMedium)),
          const SizedBox(height: 24),
          AppTextField(controller: _name, label: 'Display name', prefixIcon: Icons.person_outline_rounded, onChanged: (_) => setState(() {}), validator: (v) => Validators.required(v, 'Name')),
          const SizedBox(height: 14),
          AppTextField(
            controller: TextEditingController(text: user?.address),
            label: 'A-Mail address',
            prefixIcon: Icons.alternate_email_rounded,
            enabled: false,
            helper: 'Your address can\'t be changed.',
          ),
          const SizedBox(height: 22),
          Text('Recovery options', style: context.text.titleMedium),
          const SizedBox(height: 4),
          Text('Used to reset your password and secure your account.', style: context.text.bodySmall),
          const SizedBox(height: 14),
          AppTextField(controller: _recEmail, label: 'Recovery email', prefixIcon: Icons.mark_email_read_outlined, keyboard: TextInputType.emailAddress, validator: (v) => Validators.email(v, optional: true)),
          const SizedBox(height: 14),
          AppTextField(controller: _recPhone, label: 'Recovery phone', prefixIcon: Icons.phone_outlined, keyboard: TextInputType.phone),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Save changes', loading: _busy, onPressed: _save),
        ]),
      ),
    );
  }
}
