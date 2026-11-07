import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../navigation/route_names.dart';
import '../../providers/email_provider.dart';
import '../../providers/inbox_provider.dart';
import '../../shared/widgets/state_views.dart';
import '../inbox/email_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  final _f = FocusNode();

  @override
  void initState() {
    super.initState();
    final q = context.read<InboxProvider>().query;
    _c.text = q.text;
    WidgetsBinding.instance.addPostFrameCallback((_) => _f.requestFocus());
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _run() {
    final p = context.read<InboxProvider>();
    p.query.text = _c.text.trim();
    p.search();
  }

  void _quick(void Function(SearchQuery) f) {
    final p = context.read<InboxProvider>();
    f(p.query);
    p.query.text = _c.text.trim();
    p.search();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InboxProvider>();
    final cs = context.colors;
    final email = context.read<EmailProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _c,
          focusNode: _f,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _run(),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search in mail',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _c.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () {
                    _c.clear();
                    p.clearSearch();
                    setState(() {});
                  }),
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.tune_rounded), tooltip: 'Advanced search', onPressed: () => context.push(Routes.advancedSearch))],
      ),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _chip('Has attachment', p.query.hasAttachment, () => _quick((q) => q.hasAttachment = !q.hasAttachment)),
              _chip('Last 7 days', p.query.after != null, () => _quick((q) => q.after = q.after == null ? DateTime.now().subtract(const Duration(days: 7)) : null)),
              _chip('From me', p.query.from == 'me', () => _quick((q) => q.from = q.from == 'me' ? '' : 'me')),
              _chip('Unread', p.query.folder == 'unread', () => _quick((q) => q.folder = q.folder == 'unread' ? 'all' : 'unread')),
            ],
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant),
        Expanded(child: _body(context, p, email)),
      ]),
    );
  }

  Widget _chip(String label, bool on, VoidCallback f) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(label: Text(label), selected: on, showCheckmark: false, onSelected: (_) => f()),
      );

  Widget _body(BuildContext context, InboxProvider p, EmailProvider email) {
    switch (p.searchState) {
      case LoadState.idle:
        if (p.recent.isEmpty) {
          return StateView.empty(icon: Icons.search_rounded, title: 'Search your mail', message: 'Find messages by sender, recipient, subject, keyword, date or attachment.');
        }
        return ListView(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text('Recent searches', style: context.text.labelSmall)),
          for (final r in p.recent)
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(r),
              onTap: () {
                _c.text = r;
                _run();
              },
            ),
        ]);
      case LoadState.loading:
        return const ListSkeleton(count: 6);
      case LoadState.error:
        return StateView.error(p.searchError!, onRetry: _run);
      case LoadState.empty:
        return StateView.empty(icon: Icons.search_off_rounded, title: 'No results', message: 'Try different keywords or adjust your filters.');
      case LoadState.loaded:
        return ListView.separated(
          itemCount: p.results.length,
          separatorBuilder: (_, __) => Divider(indent: 70, color: context.colors.outlineVariant.withValues(alpha: 0.6)),
          itemBuilder: (_, i) {
            final e = p.results[i];
            return EmailTile(
              email: e,
              selected: false,
              selectionMode: false,
              onAvatarTap: () {},
              onLongPress: () {},
              onToggleStar: () => email.setStar(e.id, !e.isStarred),
              onTap: () => context.push(Routes.threadPath(e.id), extra: e),
            );
          },
        );
    }
  }
}
