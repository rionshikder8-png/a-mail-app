import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/widgets/otp_field.dart';
import 'auth_scaffold.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String _code = '';
  bool _busy = false;
  String? _error;
  int _cooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown = (_cooldown - 1).clamp(0, 99));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.length != AppConfig.otpLength) {
      setState(() => _error = 'Enter the ${AppConfig.otpLength}-digit code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await context.read<AuthProvider>().verifyEmail(_code);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      context.go(Routes.home);
    } else {
      setState(() => _error = r.error!.message);
    }
  }

  Future<void> _resend() async {
    final r = await context.read<AuthProvider>().resendVerification();
    if (!mounted) return;
    if (r.ok) {
      setState(() => _cooldown = 30);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification code sent')));
    } else {
      setState(() => _error = r.error!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return AuthScaffold(
      showBack: false,
      title: 'Verify your account',
      subtitle: 'Enter the code we sent to ${user?.recoveryEmail ?? user?.address ?? 'your email'}.',
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
        Center(
          child: TextButton(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) context.go(Routes.welcome);
            },
            child: const Text('Use a different account'),
          ),
        ),
      ]),
    );
  }
}
