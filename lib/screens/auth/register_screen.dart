import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_response.dart';
import '../../core/utils/validators.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/widgets/app_text_field.dart';
import 'auth_scaffold.dart';

enum _Avail { idle, checking, available, taken, unknown }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _recovery = TextEditingController();
  Timer? _debounce;
  _Avail _avail = _Avail.idle;
  String? _availMsg;
  bool _agreed = false;

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_name, _user, _pass, _confirm, _recovery]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onUserChanged(String v) {
    _debounce?.cancel();
    if (Validators.username(v) != null) {
      setState(() => _avail = _Avail.idle);
      return;
    }
    setState(() => _avail = _Avail.checking);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final ok = await context.read<AuthProvider>().checkUsername(v.trim().toLowerCase());
        if (!mounted) return;
        setState(() {
          _avail = ok ? _Avail.available : _Avail.taken;
          _availMsg = null;
        });
      } on ApiError catch (e) {
        if (!mounted) return;
        setState(() {
          _avail = _Avail.unknown;
          _availMsg = e.isNotConfigured || e.isOffline
              ? 'Can\'t check availability right now (server unreachable).'
              : e.message;
        });
      }
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the Terms and Privacy Policy')));
      return;
    }
    if (_avail == _Avail.taken) return;
    final auth = context.read<AuthProvider>();
    final res = await auth.register(
      username: _user.text.trim().toLowerCase(),
      password: _pass.text,
      displayName: _name.text.trim(),
      recoveryEmail: _recovery.text.trim(),
    );
    if (!mounted || res == null) return;
    context.go(Routes.verifyEmail);
  }

  Widget? _availIcon(ColorScheme cs) {
    switch (_avail) {
      case _Avail.checking:
        return const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)));
      case _Avail.available:
        return const Icon(Icons.check_circle_rounded, color: Color(0xFF1E9E63));
      case _Avail.taken:
        return Icon(Icons.cancel_rounded, color: cs.error);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AuthScaffold(
      title: 'Create your address',
      subtitle: 'Pick a username. It becomes your permanent @${AppConfig.emailDomain} identity.',
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (auth.error != null) ErrorBanner(auth.error!.message),
          AppTextField(
            controller: _name,
            label: 'Full name',
            prefixIcon: Icons.person_outline_rounded,
            action: TextInputAction.next,
            validator: (v) => Validators.required(v, 'Name'),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _user,
            label: 'Username',
            suffixText: '@${AppConfig.emailDomain}',
            prefixIcon: Icons.alternate_email_rounded,
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.next,
            validator: Validators.username,
            onChanged: _onUserChanged,
            suffix: _availIcon(cs),
            errorText: _avail == _Avail.taken ? 'That username is taken' : null,
          ),
          if (_avail == _Avail.available)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text('${_user.text.trim().toLowerCase()}@${AppConfig.emailDomain} is available',
                  style: tt.bodySmall?.copyWith(color: const Color(0xFF1E9E63))),
            ),
          if (_avail == _Avail.unknown && _availMsg != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(_availMsg!, style: tt.bodySmall),
            ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _pass,
            label: 'Password',
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            action: TextInputAction.next,
            validator: Validators.password,
            onChanged: (_) => setState(() {}),
          ),
          _StrengthBar(password: _pass.text),
          const SizedBox(height: 14),
          AppTextField(
            controller: _confirm,
            label: 'Confirm password',
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            action: TextInputAction.next,
            validator: (v) => v == _pass.text ? null : 'Passwords don\'t match',
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _recovery,
            label: 'Recovery email (optional)',
            helper: 'Used only to recover your account.',
            prefixIcon: Icons.mark_email_read_outlined,
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.done,
            validator: (v) => Validators.email(v, optional: true),
          ),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Checkbox(value: _agreed, onChanged: (v) => setState(() => _agreed = v ?? false)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('I agree to the A-Mail Terms of Service and Privacy Policy.', style: tt.bodySmall),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Create account', loading: auth.busy, onPressed: _submit),
          const SizedBox(height: 14),
          Center(
            child: TextButton(onPressed: () => context.pushReplacement(Routes.login), child: const Text('Already have an address? Sign in')),
          ),
        ]),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final String password;
  const _StrengthBar({required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox(height: 4);
    final s = Validators.passwordStrength(password);
    final cs = Theme.of(context).colorScheme;
    final colors = [cs.error, const Color(0xFFE08A00), const Color(0xFFB8A400), const Color(0xFF1E9E63), const Color(0xFF1E9E63)];
    final labels = ['Too weak', 'Weak', 'Okay', 'Strong', 'Very strong'];
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 2),
      child: Row(children: [
        Expanded(
          child: Row(children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: i < s ? colors[s] : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        Text(labels[s], style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
