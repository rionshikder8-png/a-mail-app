import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/email_provider.dart';
import '../../providers/inbox_provider.dart';
import '../../shared/dialogs/snooze_sheet.dart';
import '../../shared/widgets/sender_avatar.dart';
import '../../navigation/route_names.dart';
import 'inbox_filters.dart';
import 'inbox_list.dart';
import '../../data/repositories/misc_repository.dart';
import '../../models/label_model.dart';

/// Inbox with Gmail-like top search pill, selection toolbar and filters.
class InboxScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  const InboxScreen({super.key, required this.onOpenDrawer});
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<LabelModel> _labels = [];

  @override
  void initState() {
    super.initState();
    MiscRepository.instance.labels().then((r) {
      if (mounted && r.ok) setState(() => _labels = r.data ?? []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EmailProvider>();
    final inbox = context.watch<InboxProvider>();
    final auth = context.watch<AuthProvider>();
    final cs = context.colors;

    return Column(children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: p.selecting ? _SelectionBar(key: const ValueKey('sel')) : _SearchBar(key: const ValueKey('search'), onMenu: widget.onOpenDrawer, name: auth.user?.displayName ?? '', seed: auth.user?.username ?? ''),
      ),
      const InboxFilters(),
      Divider(height: 1, color: cs.outlineVariant),
      Expanded(
        child: InboxList(
          folder: 'inbox',
          labels: _labels,
          transform: inbox.apply,
          emptyIcon: inbox.filter == InboxFilter.all ? Icons.inbox_rounded : Icons.filter_list_off_rounded,
          emptyTitle: inbox.filter == InboxFilter.all ? 'Your inbox is empty' : 'No matching messages',
          emptyMessage: inbox.filter == InboxFilter.all
              ? 'New mail sent to your @adverune.store address will appear here.'
              : 'Try a different filter.',
        ),
      ),
    ]);
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onMenu;
  final String name;
  final String seed;
  const _SearchBar({super.key, required this.onMenu, required this.name, required this.seed});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Material(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () => context.push(Routes.search),
            child: SizedBox(
              height: 52,
              child: Row(children: [
                IconButton(onPressed: onMenu, icon: const Icon(Icons.menu_rounded), tooltip: 'Menu'),
                Expanded(child: Text('Search in mail', style: context.text.bodyLarge?.copyWith(color: cs.onSurfaceVariant))),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => context.push(Routes.settings),
                    child: SenderAvatar(name: name, seed: seed, size: 34),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EmailProvider>();
    final ids = p.selected.toList();
    final cs = context.colors;

    Future<void> run(Future<dynamic> Function() f, String done) async {
      final r = await f();
      if (!context.mounted) return;
      if (r.ok) {
        context.toast(done);
      } else {
        context.toast(r.error!.message, error: true);
      }
    }

    return SafeArea(
      bottom: false,
      child: Container(
        height: 60,
        color: cs.surfaceContainerHigh,
        child: Row(children: [
          IconButton(onPressed: p.clearSelection, icon: const Icon(Icons.close_rounded), tooltip: 'Cancel selection'),
          Text('${ids.length}', style: context.text.titleLarge),
          const Spacer(),
          IconButton(
              tooltip: 'Select all',
              onPressed: () => p.selectAll('inbox'),
              icon: const Icon(Icons.select_all_rounded)),
          IconButton(
              tooltip: 'Archive',
              onPressed: () => run(() => p.archive(ids), 'Archived'),
              icon: const Icon(Icons.archive_outlined)),
          IconButton(
              tooltip: 'Delete',
              onPressed: () => run(() => p.trash(ids), 'Moved to Trash'),
              icon: const Icon(Icons.delete_outline_rounded)),
          IconButton(
              tooltip: 'Mark as unread',
              onPressed: () => run(() => p.setRead(ids, false), 'Marked as unread'),
              icon: const Icon(Icons.mark_email_unread_outlined)),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'read':
                  run(() => p.setRead(ids, true), 'Marked as read');
                case 'snooze':
                  final when = await showSnoozeSheet(context);
                  if (when != null && context.mounted) run(() => p.snooze(ids, when), 'Snoozed');
                case 'spam':
                  run(() => p.markSpam(ids), 'Reported as spam');
                case 'important':
                  run(() => p.setImportant(ids, true), 'Marked important');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'read', child: Text('Mark as read')),
              PopupMenuItem(value: 'snooze', child: Text('Snooze')),
              PopupMenuItem(value: 'important', child: Text('Mark as important')),
              PopupMenuItem(value: 'spam', child: Text('Report spam')),
            ],
          ),
        ]),
      ),
    );
  }
}
