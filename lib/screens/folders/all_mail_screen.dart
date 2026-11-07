import 'package:flutter/material.dart';
import 'folder_scaffold.dart';

class AllMailScreen extends StatelessWidget {
  const AllMailScreen({super.key});
  @override
  Widget build(BuildContext context) => const FolderScaffold(
        folder: 'all',
        title: 'All mail',
        emptyIcon: Icons.mail_outline_rounded,
        emptyTitle: 'No mail yet',
        emptyMessage: 'Everything you send and receive, except Spam and Trash.',
      );
}
