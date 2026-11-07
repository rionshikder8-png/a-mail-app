import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class FolderModel {
  final String id;
  final String name;
  final IconData icon;
  final int unread;
  final String route;

  const FolderModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.route,
    this.unread = 0,
  });

  /// Built-in mailboxes in drawer order.
  static const system = <FolderModel>[
    FolderModel(id: FolderIds.inbox, name: 'Inbox', icon: Icons.inbox_outlined, route: '/home'),
    FolderModel(id: FolderIds.starred, name: 'Starred', icon: Icons.star_outline_rounded, route: '/folder/starred'),
    FolderModel(id: FolderIds.snoozed, name: 'Snoozed', icon: Icons.schedule_rounded, route: '/folder/snoozed'),
    FolderModel(id: FolderIds.important, name: 'Important', icon: Icons.label_important_outline_rounded, route: '/folder/important'),
    FolderModel(id: FolderIds.sent, name: 'Sent', icon: Icons.send_outlined, route: '/folder/sent'),
    FolderModel(id: FolderIds.scheduled, name: 'Scheduled', icon: Icons.outgoing_mail, route: '/folder/scheduled'),
    FolderModel(id: FolderIds.drafts, name: 'Drafts', icon: Icons.insert_drive_file_outlined, route: '/folder/drafts'),
    FolderModel(id: FolderIds.allMail, name: 'All mail', icon: Icons.mail_outline_rounded, route: '/folder/all'),
    FolderModel(id: FolderIds.spam, name: 'Spam', icon: Icons.report_gmailerrorred_outlined, route: '/folder/spam'),
    FolderModel(id: FolderIds.trash, name: 'Trash', icon: Icons.delete_outline_rounded, route: '/folder/trash'),
  ];

  static FolderModel byId(String id) =>
      system.firstWhere((f) => f.id == id, orElse: () => system.first);
}
