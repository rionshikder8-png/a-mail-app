import 'package:flutter/material.dart';
import 'folder_scaffold.dart';

class SentScreen extends StatelessWidget {
  const SentScreen({super.key});
  @override
  Widget build(BuildContext context) => const FolderScaffold(
        folder: 'sent',
        title: 'Sent',
        emptyIcon: Icons.send_outlined,
        emptyTitle: 'No sent messages',
        emptyMessage: 'Messages you send will appear here.',
      );
}
