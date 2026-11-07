import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/network/api_response.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/html_utils.dart';
import '../../data/repositories/email_repository.dart';
import '../../models/attachment_model.dart';
import '../../models/email_model.dart';
import '../../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/email_provider.dart';
import '../../shared/widgets/sender_avatar.dart';
import '../../shared/widgets/state_views.dart';
import '../email/attachment_tile.dart';
import '../email/email_actions.dart';
import '../email/reply_screen.dart';

/// Conversation view: all messages in a thread, newest expanded.
class EmailThreadScreen extends StatefulWidget {
  final String emailId;
  final EmailModel? initial;
  const EmailThreadScreen({super.key, required this.emailId, this.initial});
  @override
  State<EmailThreadScreen> createState() => _EmailThreadScreenState();
}

class _EmailThreadScreenState extends State<EmailThreadScreen> {
  List<EmailModel> _messages = [];
  LoadState _state = LoadState.loading;
  String? _error;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _messages = [widget.initial!];
      _expanded.add(widget.initial!.id);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = LoadState.loading);
    final repo = EmailRepository.instance;
    final thread = widget.initial != null ? await repo.thread(widget.initial!.threadId) : null;
    if (thread != null && thread.ok && (thread.data ?? []).isNotEmpty) {
      final l = [...thread.data!]..sort((a, b) => a.date.compareTo(b.date));
      setState(() {
        _messages = l;
        _expanded
          ..clear()
          ..add(l.last.id);
        _state = LoadState.loaded;
      });
      return;
    }
    final single = await repo.open(widget.emailId);
    if (!mounted) return;
    if (single.ok && single.data != null) {
      setState(() {
        _messages = [single.data!];
        _expanded
          ..clear()
          ..add(single.data!.id);
        _state = LoadState.loaded;
      });
    } else if (_messages.isNotEmpty) {
      setState(() => _state = LoadState.loaded); // fall back to list-provided data
    } else {
      setState(() {
        _error = single.error?.message;
        _state = LoadState.error;
      });
    }
  }

  EmailModel get _last => _messages.last;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final provider = context.read<EmailProvider>();
    final me = context.read<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        actions: _messages.isEmpty
            ? null
            : [
                IconButton(
                  tooltip: 'Archive',
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () async {
                    final r = await provider.archive(_messages.map((e) => e.id).toList());
                    if (!context.mounted) return;
                    if (r.ok) {
                      context.pop();
                      context.toast('Conversation archived');
                    } else {
                      context.toast(r.error!.message, error: true);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    final r = await provider.trash(_messages.map((e) => e.id).toList());
                    if (!context.mounted) return;
                    if (r.ok) {
                      context.pop();
                      context.toast('Moved to Trash');
                    } else {
                      context.toast(r.error!.message, error: true);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Mark as unread',
                  icon: const Icon(Icons.mark_email_unread_outlined),
                  onPressed: () async {
                    await provider.setRead([_last.id], false);
                    if (context.mounted) context.pop();
                  },
                ),
                EmailOverflowMenu(email: _last, thread: _messages),
              ],
      ),
      body: _state == LoadState.error
          ? StateView.error(
              ApiError(code: 'load_failed', message: _error ?? 'Could not load this message.'),
              onRetry: _load,
            )
          : _messages.isEmpty
              ? const ListSkeleton(count: 3)
              : ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Text(_last.subject.isEmpty ? '(no subject)' : _last.subject, style: context.text.headlineSmall),
                        ),
                        IconButton(
                          icon: Icon(_last.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: _last.isStarred ? const Color(0xFFF5B400) : cs.onSurfaceVariant),
                          onPressed: () async {
                            final r = await provider.setStar(_last.id, !_last.isStarred);
                            if (r.ok && mounted) {
                              setState(() => _messages = [
                                    ..._messages.sublist(0, _messages.length - 1),
                                    _last.copyWith(isStarred: !_last.isStarred),
                                  ]);
                            }
                          },
                        ),
                      ]),
                    ),
                    for (final m in _messages)
                      _MessageCard(
                        email: m,
                        expanded: _expanded.contains(m.id),
                        myAddress: me?.address ?? '',
                        onToggle: () => setState(() => _expanded.contains(m.id) ? _expanded.remove(m.id) : _expanded.add(m.id)),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
      bottomNavigationBar: _messages.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      onPressed: () => context.push(Routes.reply, extra: ReplyArgs(_last, false)),
                      icon: const Icon(Icons.reply_rounded, size: 20),
                      label: const Text('Reply'),
                    ),
                  ),
                  if (_last.to.length + _last.cc.length > 1) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                        onPressed: () => context.push(Routes.reply, extra: ReplyArgs(_last, true)),
                        icon: const Icon(Icons.reply_all_rounded, size: 20),
                        label: const Text('Reply all'),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      onPressed: () => context.push(Routes.forward, extra: _last),
                      icon: const Icon(Icons.forward_rounded, size: 20),
                      label: const Text('Forward'),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final EmailModel email;
  final bool expanded;
  final String myAddress;
  final VoidCallback onToggle;
  const _MessageCard({required this.email, required this.expanded, required this.myAddress, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.text;
    final body = email.bodyText.isNotEmpty ? email.bodyText : HtmlUtils.toPlain(email.bodyHtml);
    final toLine = email.to.map((a) => a.address.toLowerCase() == myAddress.toLowerCase() ? 'me' : a.display).join(', ');

    return Column(children: [
      Divider(color: cs.outlineVariant),
      InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SenderAvatar(name: email.from.display, seed: email.from.address, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(email.from.display, style: tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(DateFmt.list(email.date), style: tt.bodySmall),
                ]),
                const SizedBox(height: 2),
                Text(expanded ? 'to $toLine' : email.snippet,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
              ]),
            ),
          ]),
        ),
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Details(email: email),
            const SizedBox(height: 12),
            SelectableText(body.isEmpty ? '(No content)' : body, style: tt.bodyLarge?.copyWith(height: 1.55)),
            if (email.attachments.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('${email.attachments.length} attachment${email.attachments.length == 1 ? '' : 's'}', style: tt.labelLarge),
              const SizedBox(height: 8),
              for (final AttachmentModel a in email.attachments)
                AttachmentTile(attachment: a, onTap: () => context.push(Routes.attachment, extra: a)),
            ],
          ]),
        ),
    ]);
  }
}

class _Details extends StatefulWidget {
  final EmailModel email;
  const _Details({required this.email});
  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final tt = context.text;
    final e = widget.email;
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 52, child: Text(k, style: tt.bodySmall)),
            Expanded(child: Text(v, style: tt.bodySmall?.copyWith(color: context.colors.onSurface))),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => setState(() => _open = !_open),
        child: Text(_open ? 'Hide details' : 'View details', style: tt.labelMedium?.copyWith(color: context.colors.primary)),
      ),
      if (_open) ...[
        const SizedBox(height: 8),
        row('From', '${e.from.name.isEmpty ? '' : '${e.from.name} '}<${e.from.address}>'),
        row('To', e.to.map((a) => a.address).join(', ')),
        if (e.cc.isNotEmpty) row('Cc', e.cc.map((a) => a.address).join(', ')),
        row('Date', DateFmt.full(e.date)),
      ],
    ]);
  }
}
