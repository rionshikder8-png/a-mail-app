import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';

class _Plan {
  final String id;
  final String name;
  final String storage;
  final String blurb;
  final List<String> features;
  const _Plan(this.id, this.name, this.storage, this.blurb, this.features);
}

/// Plan presentation only. Prices, limits and checkout come from the backend; nothing here can be purchased.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  static const _plans = [
    _Plan('free', 'Free', 'Base storage', 'Everything you need to get started.', ['Your @adverune.store address', 'Labels, search and snooze', 'Standard support']),
    _Plan('plus', 'Plus', 'More storage', 'For people who live in their inbox.', ['Additional mailbox storage', 'Larger attachments', 'Priority support']),
    _Plan('pro', 'Professional', 'Most storage', 'For professionals and small teams.', ['Maximum mailbox storage', 'Advanced security controls', 'Dedicated support']),
  ];

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AuthProvider>().user?.plan ?? 'free';
    final cs = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: cs.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Paid plans are not available yet. Pricing and upgrades will appear here once billing is live.', style: context.text.bodySmall?.copyWith(color: cs.onSurface))),
          ]),
        ),
        const SizedBox(height: 16),
        for (final p in _plans)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.id == current ? cs.primary : cs.outlineVariant, width: p.id == current ? 2 : 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(p.name, style: context.text.titleLarge),
                const Spacer(),
                if (p.id == current)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(20)),
                    child: Text('Current', style: context.text.labelMedium?.copyWith(color: cs.onPrimary)),
                  ),
              ]),
              const SizedBox(height: 2),
              Text(p.storage, style: context.text.labelLarge?.copyWith(color: cs.primary)),
              const SizedBox(height: 6),
              Text(p.blurb, style: context.text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              for (final f in p.features)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [Icon(Icons.check_rounded, size: 18, color: cs.primary), const SizedBox(width: 10), Expanded(child: Text(f))]),
                ),
              if (p.id != current) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: null, child: const Text('Coming soon')),
              ],
            ]),
          ),
        TextButton(onPressed: () => context.push(Routes.subscription), child: const Text('Manage subscription')),
      ]),
    );
  }
}
