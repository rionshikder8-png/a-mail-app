import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../providers/email_provider.dart';
import '../../shared/dialogs/dialogs.dart';
import '../inbox/inbox_list.dart';
import '../../models/email_model.dart';
import '../../navigation/route_names.dart';

/// Shared body for the secondary mailboxes.
class FolderScaffold extends StatelessWidget {
  final String folder;
  final String title;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final Widget? banner;
  final List<Widget> extraActions;
  final void Function(EmailModel)? onOpen;
  final bool swipe;

  const FolderScaffold({
    super.key,
    required this.folder,
    required this.title,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.banner,
    this.extraActions = const [],
    this.onOpen,
    this.swipe = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EmailProvider>();
    final cs = context.colors;
    final ids = p.selected.toList();

    Future<void> run(Future<dynamic> f, String ok) async {
      final r = await f;
      if (!context.mounted) return;
      context.toast(r.ok ? ok : r.error!.message, error: !r.ok);
    }

    return PopScope(
      canPop: !p.selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) p.clearSelection();
      },
      child: Scaffold(
        appBar: p.selecting
            ? AppBar(
                backgroundColor: cs.surfaceContainerHigh,
                leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: p.clearSelection),
                title: Text('${ids.length} selected'),
                actions: [
                  IconButton(icon: const Icon(Icons.select_all_rounded), tooltip: 'Select all', onPressed: () => p.selectAll(folder)),
                  if (folder == 'trash') ...[
                    IconButton(icon: const Icon(Icons.restore_from_trash_rounded), tooltip: 'Restore', onPressed: () => run(p.restore(ids), 'Restored')),
                    IconButton(
                      icon: const Icon(Icons.delete_forever_outlined),
                      tooltip: 'Delete forever',
                      onPressed: () async {
                        if (await confirmDialog(context, title: 'Delete forever?', message: '${ids.length} conversation(s) will be permanently deleted.', confirmLabel: 'Delete', destructive: true)) {
                          run(p.deleteForever(ids), 'Deleted forever');
                        }
                      },
                    ),
                  ] else if (folder == 'spam') ...[
                    IconButton(icon: const Icon(Icons.inbox_rounded), tooltip: 'Not spam', onPressed: () => run(p.notSpam(ids), 'Moved to Inbox')),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Delete', onPressed: () => run(p.trash(ids), 'Moved to Trash')),
                  ] else ...[
                    IconButton(icon: const Icon(Icons.archive_outlined), tooltip: 'Archive', onPressed: () => run(p.archive(ids), 'Archived')),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Delete', onPressed: () => run(p.trash(ids), 'Moved to Trash')),
                    IconButton(icon: const Icon(Icons.mark_email_unread_outlined), tooltip: 'Mark unread', onPressed: () => run(p.setRead(ids, false), 'Marked as unread')),
                  ],
                ],
              )
            : AppBar(
                title: Text(title),
                actions: [
                  IconButton(icon: const Icon(Icons.search_rounded), tooltip: 'Search', onPressed: () => context.push(Routes.search)),
                  ...extraActions,
                ],
              ),
        body: Column(children: [
          if (banner != null) banner!,
          Expanded(
            child: InboxList(
              folder: folder,
              emptyIcon: emptyIcon,
              emptyTitle: emptyTitle,
              emptyMessage: emptyMessage,
              onOpen: onOpen,
              enableSwipe: swipe,
            ),
          ),
        ]),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const InfoBanner({super.key, required this.text, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHigh,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(children: [
        Expanded(child: Text(text, style: context.text.bodySmall)),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ]),
    );
  }
}
