import 'package:flutter/material.dart';
import 'all_mail_screen.dart';
import 'drafts_screen.dart';
import 'important_screen.dart';
import 'scheduled_screen.dart';
import 'sent_screen.dart';
import 'snoozed_screen.dart';
import 'spam_screen.dart';
import 'starred_screen.dart';
import 'trash_screen.dart';

class FolderScreenRouter extends StatelessWidget {
  final String folderId;
  const FolderScreenRouter({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    switch (folderId) {
      case 'starred':
        return const StarredScreen();
      case 'snoozed':
        return const SnoozedScreen();
      case 'important':
        return const ImportantScreen();
      case 'sent':
        return const SentScreen();
      case 'scheduled':
        return const ScheduledScreen();
      case 'drafts':
        return const DraftsScreen();
      case 'all':
        return const AllMailScreen();
      case 'spam':
        return const SpamScreen();
      case 'trash':
        return const TrashScreen();
      default:
        return Scaffold(appBar: AppBar(), body: const Center(child: Text('Unknown mailbox')));
    }
  }
}
