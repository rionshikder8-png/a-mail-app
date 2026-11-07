import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../shared/components/primary_button.dart';
import '../../shared/widgets/brand_logo.dart';

class _Page {
  final IconData icon;
  final String title;
  final String body;
  const _Page(this.icon, this.title, this.body);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  static const _pages = [
    _Page(Icons.alternate_email_rounded, 'Your own @adverune.store address',
        'Get a professional address that is truly yours, on a platform built around your identity.'),
    _Page(Icons.inbox_rounded, 'An inbox that stays out of your way',
        'Conversations, labels, stars, snooze and powerful search, designed for speed on mobile.'),
    _Page(Icons.shield_outlined, 'Private and secure by design',
        'Encrypted sessions, biometric unlock, two-factor sign-in and full control of your devices.'),
  ];

  Future<void> _finish() async {
    await context.read<AuthProvider>().completeOnboarding();
    if (mounted) context.go(Routes.welcome);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final last = _i == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const BrandWordmark(height: 22),
              TextButton(onPressed: _finish, child: const Text('Skip')),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _pages.length,
              onPageChanged: (v) => setState(() => _i = v),
              itemBuilder: (_, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      width: 148,
                      height: 148,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary.withValues(alpha: 0.09),
                      ),
                      child: Icon(p.icon, size: 64, color: cs.primary),
                    ),
                    const SizedBox(height: 44),
                    Text(p.title, style: tt.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    Text(p.body, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                  ]),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < _pages.length; k++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: k == _i ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: k == _i ? cs.primary : cs.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: PrimaryButton(
              label: last ? 'Get started' : 'Next',
              onPressed: () => last
                  ? _finish()
                  : _pc.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic),
            ),
          ),
        ]),
      ),
    );
  }
}
