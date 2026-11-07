import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../navigation/route_names.dart';
import '../../providers/email_provider.dart';
import '../contacts/contacts_screen.dart';
import '../inbox/inbox_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import 'bottom_navigation.dart';
import 'home_drawer.dart';

/// Main shell: Mail / Contacts / Alerts / Settings with a Gmail-style drawer and Compose FAB.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffold = GlobalKey<ScaffoldState>();
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final selecting = context.select<EmailProvider, bool>((p) => p.selecting);
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final pages = <Widget>[
      InboxScreen(onOpenDrawer: () => _scaffold.currentState?.openDrawer()),
      const ContactsScreen(embedded: true),
      const NotificationsScreen(embedded: true),
      const SettingsScreen(embedded: true),
    ];

    return PopScope(
      canPop: _tab == 0 && !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (selecting) {
          context.read<EmailProvider>().clearSelection();
        } else if (_tab != 0) {
          setState(() => _tab = 0);
        }
      },
      child: Scaffold(
        key: _scaffold,
        drawer: const HomeDrawer(),
        body: wide
            ? Row(children: [
                NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  labelType: NavigationRailLabelType.all,
                  leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => _scaffold.currentState?.openDrawer()),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.mail_outline_rounded), selectedIcon: Icon(Icons.mail_rounded), label: Text('Mail')),
                    NavigationRailDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: Text('Contacts')),
                    NavigationRailDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: Text('Alerts')),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: Text('Settings')),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: IndexedStack(index: _tab, children: pages)),
              ])
            : IndexedStack(index: _tab, children: pages),
        floatingActionButton: _tab == 0 && !selecting
            ? FloatingActionButton.extended(
                heroTag: 'compose',
                onPressed: () => context.push(Routes.compose),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Compose'),
              )
            : null,
        bottomNavigationBar: wide ? null : HomeBottomNav(index: _tab, onSelect: (i) => setState(() => _tab = i)),
      ),
    );
  }
}
