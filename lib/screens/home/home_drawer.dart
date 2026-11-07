import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/repositories/misc_repository.dart';
import '../../models/folder_model.dart';
import '../../models/label_model.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/email_provider.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/sender_avatar.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({super.key});
  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  List<LabelModel> _labels = [];
  bool _accountOpen = false;

  @override
  void initState() {
    super.initState();
    MiscRepository.instance.labels().then((r) {
      if (mounted && r.ok) setState(() => _labels = r.data ?? []);
    });
  }

  void _go(String route) {
    Navigator.pop(context);
    if (route == Routes.home) return;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final user = context.watch<AuthProvider>().user;
    final email = context.watch<EmailProvider>();

    return Drawer(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [const BrandMark(height: 30), const SizedBox(width: 10), const BrandWordmark(height: 22)]),
          ),
          InkWell(
            onTap: () => setState(() => _accountOpen = !_accountOpen),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Row(children: [
                SenderAvatar(name: user?.displayName ?? '', seed: user?.username, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.displayName ?? '', style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(user?.address ?? '', style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                Icon(_accountOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              ]),
            ),
          ),
          if (_accountOpen)
            Container(
              color: cs.surfaceContainerLow,
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Manage your account'),
                  onTap: () => _go(Routes.account),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: () async {
                    Navigator.pop(context);
                    context.read<EmailProvider>().reset();
                    await context.read<AuthProvider>().signOut();
                  },
                ),
              ]),
            ),
          Divider(color: cs.outlineVariant),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
              for (final f in FolderModel.system) ...[
                if (f.id == 'sent' || f.id == 'all') Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Divider(color: cs.outlineVariant)),
                _DrawerItem(
                  icon: f.icon,
                  label: f.name,
                  count: f.id == 'inbox' ? email.unreadCount('inbox') : 0,
                  selected: f.id == 'inbox',
                  onTap: () => _go(f.route),
                ),
              ],
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Divider(color: cs.outlineVariant)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(children: [
                  Expanded(child: Text('Labels', style: context.text.labelSmall)),
                  TextButton(onPressed: () => _go(Routes.labels), child: const Text('Manage')),
                ]),
              ),
              if (_labels.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('No labels yet', style: context.text.bodySmall),
                ),
              for (final l in _labels)
                _DrawerItem(
                  icon: Icons.label_rounded,
                  iconColor: Color(l.colorValue),
                  label: l.name,
                  count: 0,
                  selected: false,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(Routes.labelPath(l.id), extra: l.name);
                  },
                ),
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Divider(color: cs.outlineVariant)),
              _DrawerItem(icon: Icons.contacts_outlined, label: 'Contacts', onTap: () => _go(Routes.contacts)),
              _DrawerItem(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => _go(Routes.notifications)),
              _DrawerItem(icon: Icons.cloud_outlined, label: 'Storage', onTap: () => _go(Routes.storageManager)),
              _DrawerItem(icon: Icons.workspace_premium_outlined, label: 'Plans', onTap: () => _go(Routes.plans)),
              _DrawerItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () => _go(Routes.settings)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.iconColor, this.count = 0, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? cs.primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(children: [
              const SizedBox(width: 16),
              Icon(icon, size: 22, color: iconColor ?? (selected ? cs.primary : cs.onSurfaceVariant)),
              const SizedBox(width: 18),
              Expanded(
                child: Text(label,
                    style: context.text.bodyLarge?.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? cs.primary : cs.onSurface)),
              ),
              if (count > 0) Padding(padding: const EdgeInsets.only(right: 16), child: Text('$count', style: context.text.labelMedium)),
            ]),
          ),
        ),
      ),
    );
  }
}
