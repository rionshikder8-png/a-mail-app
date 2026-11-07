import 'package:flutter/material.dart';
import 'folder_scaffold.dart';

class ImportantScreen extends StatelessWidget {
  const ImportantScreen({super.key});
  @override
  Widget build(BuildContext context) => const FolderScaffold(
        folder: 'important',
        title: 'Important',
        emptyIcon: Icons.label_important_outline_rounded,
        emptyTitle: 'Nothing marked important',
        emptyMessage: 'Messages you mark as important appear here.',
      );
}
