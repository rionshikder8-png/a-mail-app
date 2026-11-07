import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/state_views.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<AuthProvider>().user?.plan ?? 'free';
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: Column(children: [
        ListTile(
          leading: const Icon(Icons.workspace_premium_outlined),
          title: const Text('Current plan'),
          trailing: Text(plan.toUpperCase(), style: context.text.labelLarge),
        ),
        const Divider(),
        Expanded(
          child: StateView.empty(
            icon: Icons.receipt_long_outlined,
            title: 'No billing history',
            message: 'Invoices and renewal details will appear here when paid plans launch.',
          ),
        ),
      ]),
    );
  }
}
