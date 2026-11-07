import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../navigation/route_names.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/widgets/brand_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const Spacer(flex: 2),
            const BrandLockup(markHeight: 96),
            const SizedBox(height: 28),
            Text(AppConfig.tagline, style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            const Spacer(flex: 3),
            PrimaryButton(label: 'Create your A-Mail address', onPressed: () => context.push(Routes.register)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => context.push(Routes.login), child: const Text('Sign in')),
            const SizedBox(height: 20),
            Text('BY ${AppConfig.brand.toUpperCase()}', style: tt.labelSmall?.copyWith(letterSpacing: 2.4)),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
