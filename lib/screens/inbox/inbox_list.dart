import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../models/email_model.dart';
import '../../models/label_model.dart';
import '../../navigation/route_names.dart';
import '../../providers/email_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/widgets/state_views.dart';
import 'email_tile.dart';

/// A reusable, swipeable, paged, selectable list of emails for any mailbox.
class InboxList extends StatefulWidget {
  final String folder;
  final String? labelId;
  final List<EmailModel> Function(List<EmailModel>)? transform;
  final List<LabelModel> labels;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final bool enableSwipe;
  final Widget? header;
  final void Function(EmailModel)? onOpen;

  const InboxList({
    super.key,
    required this.folder,
    this.labelId,
    this.transform,
    this.labels = const [],
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyTitle = 'Nothing here',
    this.emptyMessage = 'Messages will show up here.',
    this.enableSwipe = true,
    this.header,
    this.onOpen,
  });

  @override
  State<InboxList> createState() => _InboxListState();
}

class _InboxListState extends State<InboxList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        context.read<EmailProvider>().loadMore(widget.folder, labelId: widget.labelId);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmailProvider>().load(widget.folder, labelId: widget.labelId);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() => context.read<EmailProvider>().load(widget.folder, labelId: widget.labelId, refresh: true);

  Future<void> _swipe(EmailModel e, SwipeAction a) async {
    final p = context.read<EmailProvider>();
    final snap = p.snapshotOf([e.id]);
    final messenger = ScaffoldMessenger.of(context);
    if (a == SwipeAction.archive) {
      final r = await p.archive([e.id]);
      if (!mounted) return;
      if (!r.ok) return context.toast(r.error!.message, error: true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('Conversation archived'),
          action: SnackBarAction(label: 'Undo', onPressed: () { p.undoRemove(snap, widget.folder, () => p.restore([e.id])); }),
        ));
    } else if (a == SwipeAction.delete) {
      final r = widget.folder == 'trash' ? await p.deleteForever([e.id]) : await p.trash([e.id]);
      if (!mounted) return;
      if (!r.ok) return context.toast(r.error!.message, error: true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(widget.folder == 'trash' ? 'Deleted forever' : 'Moved to Trash'),
          action: widget.folder == 'trash'
              ? null
              : SnackBarAction(label: 'Undo', onPressed: () { p.undoRemove(snap, widget.folder, () => p.restore([e.id])); }),
        ));
    }
  }

  Widget _swipeBg(BuildContext context, SwipeAction a, Alignment al) {
    final cs = context.colors;
    final isArchive = a == SwipeAction.archive;
    return Container(
      color: isArchive ? cs.primary : cs.error,
      alignment: al,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(isArchive ? Icons.archive_outlined : Icons.delete_outline_rounded, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EmailProvider>();
    final settings = context.watch<SettingsProvider>();
    final box = p.box(widget.folder, labelId: widget.labelId);

    if (box.state == LoadState.loading && box.items.isEmpty || box.state == LoadState.idle) {
      return const ListSkeleton();
    }
    if (box.state == LoadState.error && box.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (_, c) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(height: c.maxHeight, child: StateView.error(box.error!, onRetry: _refresh)),
          ),
        ),
      );
    }

    final items = widget.transform != null ? widget.transform!(box.items) : box.items;
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (_, c) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: c.maxHeight,
              child: StateView.empty(icon: widget.emptyIcon, title: widget.emptyTitle, message: widget.emptyMessage),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Column(children: [
        if (box.fromCache) const OfflineBanner(),
        if (widget.header != null) widget.header!,
        Expanded(
          child: ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length + (box.loadingMore ? 1 : 0),
            separatorBuilder: (_, __) => Divider(indent: 70, color: context.colors.outlineVariant.withValues(alpha: 0.6)),
            itemBuilder: (_, i) {
              if (i >= items.length) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))));
              }
              final e = items[i];
              final tile = EmailTile(
                email: e,
                labels: widget.labels,
                compact: settings.compactDensity,
                selected: p.selected.contains(e.id),
                selectionMode: p.selecting,
                onToggleStar: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final errColor = context.colors.error;
                  final r = await p.setStar(e.id, !e.isStarred);
                  if (!r.ok) {
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(r.error!.message), backgroundColor: errColor));
                  }
                },
                onAvatarTap: () => p.toggleSelect(e.id),
                onLongPress: () => p.toggleSelect(e.id),
                onTap: () {
                  if (p.selecting) {
                    p.toggleSelect(e.id);
                    return;
                  }
                  if (widget.onOpen != null) {
                    widget.onOpen!(e);
                    return;
                  }
                  if (e.isDraft) {
                    context.push(Routes.compose, extra: e);
                    return;
                  }
                  if (!e.isRead) p.setRead([e.id], true);
                  context.push(Routes.threadPath(e.id), extra: e);
                },
              );
              if (!widget.enableSwipe || p.selecting) return tile;
              return Dismissible(
                key: ValueKey('${widget.folder}-${e.id}'),
                background: _swipeBg(context, settings.swipeRight, Alignment.centerLeft),
                secondaryBackground: _swipeBg(context, settings.swipeLeft, Alignment.centerRight),
                confirmDismiss: (dir) async {
                  final a = dir == DismissDirection.startToEnd ? settings.swipeRight : settings.swipeLeft;
                  if (a == SwipeAction.none) return false;
                  _swipe(e, a);
                  return false; // provider removes the item; avoids Dismissible tree assertion
                },
                child: tile,
              );
            },
          ),
        ),
      ]),
    );
  }
}
