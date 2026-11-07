import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/validators.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/widgets/app_text_field.dart';
import 'auth_scaffold.dart';
import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final id = _id.text.trim().toLowerCase();
    final r = await context.read<AuthProvider>().forgotPassword(id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      context.push(Routes.verifyOtp, extra: OtpArgs(identifier: id, purpose: OtpPurpose.passwordReset));
    } else {
      setState(() => _error = r.error!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset your password',
      subtitle: 'Enter your A-Mail address or recovery email. We\'ll send a ${AppConfig.otpLength}-digit code.',
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_error != null) ErrorBanner(_error!),
          AppTextField(
            controller: _id,
            label: 'Address or recovery email',
            prefixIcon: Icons.alternate_email_rounded,
            keyboard: TextInputType.emailAddress,
            action: TextInputAction.done,
            validator: (v) => Validators.required(v, 'This field'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Send code', loading: _busy, onPressed: _submit),
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: () => context.push(Routes.recovery), child: const Text('Other recovery options'))),
        ]),
      ),
    );
  }
}
