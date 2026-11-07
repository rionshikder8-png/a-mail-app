import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../providers/email_provider.dart';
import 'folder_scaffold.dart';

class SnoozedScreen extends StatelessWidget {
  const SnoozedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<EmailProvider>();
    return FolderScaffold(
      folder: 'snoozed',
      title: 'Snoozed',
      emptyIcon: Icons.schedule_rounded,
      emptyTitle: 'No snoozed messages',
      emptyMessage: 'Snooze a message to have it return to your inbox later.',
      extraActions: [
        if (p.selecting)
          IconButton(
            icon: const Icon(Icons.alarm_off_rounded),
            tooltip: 'Unsnooze',
            onPressed: () async {
              final r = await p.unsnooze(p.selected.toList());
              if (context.mounted) context.toast(r.ok ? 'Moved to Inbox' : r.error!.message, error: !r.ok);
            },
          ),
      ],
    );
  }
}
