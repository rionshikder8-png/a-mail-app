import 'package:flutter/material.dart';
import 'folder_scaffold.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});
  @override
  Widget build(BuildContext context) => const FolderScaffold(
        folder: 'trash',
        title: 'Trash',
        emptyIcon: Icons.delete_outline_rounded,
        emptyTitle: 'Trash is empty',
        emptyMessage: 'Messages in Trash are deleted forever after 30 days.',
        banner: InfoBanner(text: 'Messages in Trash are deleted after 30 days.'),
      );
}
