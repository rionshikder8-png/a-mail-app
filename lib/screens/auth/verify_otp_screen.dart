import 'dart:async';
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

enum OtpPurpose { passwordReset, recovery }

class OtpArgs {
  final String identifier;
  final OtpPurpose purpose;
  const OtpArgs({required this.identifier, required this.purpose});
}

/// Step 1: enter the code. Step 2: choose a new password.
class VerifyOtpScreen extends StatefulWidget {
  final OtpArgs args;
  const VerifyOtpScreen({super.key, required this.args});
  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  String _code = '';
  bool _busy = false;
  bool _verified = false;
  String? _error;
  int _cooldown = 30;
  Timer? _timer;
  final _form = GlobalKey<FormState>();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
      }
      if (mounted) setState(() => _cooldown = (_cooldown - 1).clamp(0, 99));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (Validators.otp(_code) != null) {
      setState(() => _error = Validators.otp(_code));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await context.read<AuthProvider>().verifyOtp(widget.args.identifier, _code, 'password_reset');
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r.ok) {
        _verified = true;
      } else {
        _error = r.error!.message;
      }
    });
  }

  Future<void> _resend() async {
    final r = await context.read<AuthProvider>().forgotPassword(widget.args.identifier);
    if (!mounted) return;
    if (r.ok) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A new code was sent')));
    } else {
      setState(() => _error = r.error!.message);
    }
  }

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await context.read<AuthProvider>().resetPassword(widget.args.identifier, _code, _pw.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Please sign in.')));
      context.go(Routes.login);
    } else {
      setState(() => _error = r.error!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verified) {
      return AuthScaffold(
        title: 'Choose a new password',
        subtitle: 'Make it unique and at least ${AppConfig.passwordMinLength} characters.',
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null) ErrorBanner(_error!),
            AppTextField(controller: _pw, label: 'New password', obscure: true, prefixIcon: Icons.lock_outline_rounded, validator: Validators.password, action: TextInputAction.next),
            const SizedBox(height: 14),
            AppTextField(
              controller: _pw2,
              label: 'Confirm new password',
              obscure: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (v) => v == _pw.text ? null : 'Passwords don\'t match',
              action: TextInputAction.done,
              onSubmitted: (_) => _reset(),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Update password', loading: _busy, onPressed: _reset),
          ]),
        ),
      );
    }
    return AuthScaffold(
      title: 'Enter the code',
      subtitle: 'We sent a ${AppConfig.otpLength}-digit code to ${widget.args.identifier}.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null) ErrorBanner(_error!),
        OtpField(hasError: _error != null, onChanged: (v) => _code = v, onCompleted: (v) {
          _code = v;
          _verify();
        }),
        const SizedBox(height: 28),
        PrimaryButton(label: 'Verify', loading: _busy, onPressed: _verify),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _cooldown == 0 ? _resend : null,
            child: Text(_cooldown == 0 ? 'Resend code' : 'Resend code in ${_cooldown}s'),
          ),
        ),
      ]),
    );
  }
}
