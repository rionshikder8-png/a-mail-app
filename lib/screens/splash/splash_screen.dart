import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  bool _navigated = false;
  late final AuthProvider _auth = context.read<AuthProvider>();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_maybeGo);
    Future.delayed(const Duration(milliseconds: 1400), _maybeGo);
  }

  void _maybeGo() {
    if (_navigated || !mounted || _auth.status == AuthStatus.unknown) return;
    if (_c.status != AnimationStatus.completed) return;
    _navigated = true;
    if (_auth.status == AuthStatus.signedIn) {
      context.go(Routes.home);
    } else {
      context.go(_auth.onboardingDone ? Routes.welcome : Routes.onboarding);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_maybeGo);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: Center(
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: Tween(begin: 0.92, end: 1.0).animate(fade),
                  child: const BrandLockup(markHeight: 110),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: fade,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(children: [
                Text(AppConfig.tagline, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text('BY ${AppConfig.brand.toUpperCase()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2.4)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
