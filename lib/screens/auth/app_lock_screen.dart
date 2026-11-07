import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/widgets/brand_logo.dart';

/// Full-screen overlay shown when biometric unlock is enabled.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});
  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _try());
  }

  Future<void> _try() async {
    final ok = await context.read<AuthProvider>().unlock();
    if (mounted && !ok) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            const Spacer(),
            const BrandMark(height: 72),
            const SizedBox(height: 24),
            Text('A-Mail is locked', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_failed ? 'Authentication failed. Try again.' : 'Authenticate to continue.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const Spacer(),
            PrimaryButton(label: 'Unlock', icon: Icons.fingerprint_rounded, onPressed: _try),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<AuthProvider>().signOut(),
              child: const Text('Sign out instead'),
            ),
          ]),
        ),
      ),
    );
  }
}
