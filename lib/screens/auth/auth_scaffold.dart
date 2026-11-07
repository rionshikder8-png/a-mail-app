import 'package:flutter/material.dart';
import '../../shared/widgets/brand_logo.dart';

/// Shared chrome for all authentication screens.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.child, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(leading: showBack && Navigator.of(context).canPop() ? const BackButton() : null),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 24, maxWidth: 480),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const BrandMark(height: 40),
                const SizedBox(height: 24),
                Text(title, style: tt.headlineMedium),
                const SizedBox(height: 8),
                Text(subtitle, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 28),
                child,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.error))),
      ]),
    );
  }
}
