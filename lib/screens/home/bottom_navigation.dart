import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/email_provider.dart';
import '../../providers/notification_provider.dart';

class HomeBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const HomeBottomNav({super.key, required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final unread = context.select<EmailProvider, int>((p) => p.unreadCount('inbox'));
    final notif = context.select<NotificationProvider, int>((p) => p.unread);
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onSelect,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.mail_outline_rounded)),
          selectedIcon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.mail_rounded)),
          label: 'Mail',
        ),
        const NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Contacts'),
        NavigationDestination(
          icon: Badge(isLabelVisible: notif > 0, label: Text('$notif'), child: const Icon(Icons.notifications_none_rounded)),
          selectedIcon: Badge(isLabelVisible: notif > 0, label: Text('$notif'), child: const Icon(Icons.notifications_rounded)),
          label: 'Alerts',
        ),
        const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
      ],
    );
  }
}
