import 'package:flutter/material.dart';
import 'folder_scaffold.dart';

class ScheduledScreen extends StatelessWidget {
  const ScheduledScreen({super.key});
  @override
  Widget build(BuildContext context) => const FolderScaffold(
        folder: 'scheduled',
        title: 'Scheduled',
        emptyIcon: Icons.outgoing_mail,
        emptyTitle: 'Nothing scheduled',
        emptyMessage: 'Use "Schedule send" in Compose to send a message later.',
        swipe: false,
      );
}
