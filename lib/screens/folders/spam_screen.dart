import 'package:flutter/material.dart';
import 'folder_scaffold.dart';

class SpamScreen extends StatelessWidget {
  const SpamScreen({super.key});
  @override
  Widget build(BuildContext context) => const FolderScaffold(
        folder: 'spam',
        title: 'Spam',
        emptyIcon: Icons.report_gmailerrorred_outlined,
        emptyTitle: 'No spam',
        emptyMessage: 'Spam older than 30 days is deleted automatically.',
        banner: InfoBanner(text: 'Messages in Spam are deleted after 30 days.'),
      );
}
