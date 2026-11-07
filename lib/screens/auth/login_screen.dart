import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/validators.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/otp_field.dart';
import 'auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  String _normalise(String v) {
    final s = v.trim().toLowerCase();
    final at = '@${AppConfig.emailDomain}';
    return s.endsWith(at) ? s.substring(0, s.length - at.length) : s;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final res = await auth.login(_normalise(_user.text), _pass.text);
    if (!mounted || res == null) return;
    if (res.twoFactorChallengeId != null) {
      await _askTwoFactor();
    } else if (res.needsEmailVerification) {
      context.go(Routes.verifyEmail);
    }
  }

  Future<void> _askTwoFactor() async {
    String code = '';
    final auth = context.read<AuthProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(c).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Two-factor verification', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Enter the ${AppConfig.otpLength}-digit code from your authenticator.',
              style: Theme.of(c).textTheme.bodyMedium?.copyWith(color: Theme.of(c).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 22),
          OtpField(onChanged: (v) => code = v, onCompleted: (v) async {
            code = v;
            final r = await auth.submitTwoFactor(code);
            if (c.mounted && r != null) Navigator.pop(c);
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthScaffold(
      title: 'Sign in',
      subtitle: 'Use your ${AppConfig.emailDomain} address to continue.',
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (auth.error != null) ErrorBanner(auth.error!.message),
          AppTextField(
            controller: _user,
            label: 'Username or address',
            suffixText: '@${AppConfig.emailDomain}',
            prefixIcon: Icons.alternate_email_rounded,
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.next,
            validator: (v) => Validators.required(v, 'Username'),
            onChanged: (_) => auth.error != null ? auth.clearError() : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _pass,
            label: 'Password',
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            action: TextInputAction.done,
            validator: (v) => Validators.required(v, 'Password'),
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => context.push(Routes.forgot), child: const Text('Forgot password?')),
          ),
          const SizedBox(height: 8),
          PrimaryButton(label: 'Sign in', loading: auth.busy, onPressed: _submit),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: () => context.pushReplacement(Routes.register),
              child: const Text('New to A-Mail? Create an address'),
            ),
          ),
        ]),
      ),
    );
  }
}
