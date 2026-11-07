import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/repositories/misc_repository.dart';
import '../../models/contact_model.dart';
import '../../models/email_model.dart';
import '../../navigation/app_router.dart';
import '../../navigation/route_names.dart';
import '../../providers/email_provider.dart';
import '../../shared/widgets/sender_avatar.dart';
import '../../shared/widgets/state_views.dart';

class ContactsScreen extends StatefulWidget {
  final bool embedded;
  final bool pickMode;
  const ContactsScreen({super.key, this.embedded = false, this.pickMode = false});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<ContactModel> _all = [];
  LoadState _state = LoadState.loading;
  String? _error;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = LoadState.loading);
    final r = await MiscRepository.instance.contacts();
    if (!mounted) return;
    setState(() {
      if (r.ok) {
        _all = [...?r.data]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _state = _all.isEmpty ? LoadState.empty : LoadState.loaded;
      } else {
        _error = r.error!.message;
        _state = LoadState.error;
      }
    });
  }

  Future<void> _open([ContactModel? c]) async {
    final changed = await context.push<bool>(Routes.contactDetails, extra: c);
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final list = _q.isEmpty
        ? _all
        : _all.where((c) => c.name.toLowerCase().contains(_q) || c.email.toLowerCase().contains(_q)).toList();

    final body = Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search contacts',
            prefixIcon: const Icon(Icons.search_rounded),
            fillColor: cs.surfaceContainerHigh,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide(color: cs.primary)),
          ),
        ),
      ),
      Expanded(
        child: switch (_state) {
          LoadState.loading || LoadState.idle => const ListSkeleton(count: 7),
          LoadState.error => StateView(icon: Icons.cloud_off_rounded, title: 'Couldn\'t load contacts', message: _error ?? '', actionLabel: 'Retry', onAction: _load),
          LoadState.empty => StateView(
              icon: Icons.people_outline_rounded,
              title: 'No contacts yet',
              message: 'Save people you email often for quick compose.',
              actionLabel: 'Add contact',
              onAction: _open,
            ),
          LoadState.loaded => list.isEmpty
              ? StateView.empty(icon: Icons.search_off_rounded, title: 'No matches', message: 'No contact matches "$_q".')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final c = list[i];
                      final header = i == 0 || list[i - 1].name.isEmpty || c.name.isEmpty || list[i - 1].name[0].toLowerCase() != c.name[0].toLowerCase();
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (header && c.name.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
                            child: Text(c.name[0].toUpperCase(), style: context.text.labelMedium?.copyWith(color: cs.primary)),
                          ),
                        ListTile(
                          leading: SenderAvatar(name: c.name, seed: c.email, size: 40),
                          title: Text(c.name),
                          subtitle: Text(c.email),
                          trailing: widget.pickMode
                              ? null
                              : IconButton(
                                  tooltip: 'Compose',
                                  icon: const Icon(Icons.mail_outline_rounded),
                                  onPressed: () => context.push(Routes.compose, extra: ComposeArgs(to: [EmailAddress(name: c.name, address: c.email)])),
                                ),
                          onTap: () => widget.pickMode ? context.pop(c) : _open(c),
                        ),
                      ]);
                    },
                  ),
                ),
        },
      ),
    ]);

    if (widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contacts')),
        floatingActionButton: FloatingActionButton(heroTag: 'add_contact', onPressed: _open, tooltip: 'Add contact', child: const Icon(Icons.person_add_alt_1_outlined)),
        body: body,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.pickMode ? 'Choose a contact' : 'Contacts')),
      floatingActionButton: widget.pickMode ? null : FloatingActionButton(onPressed: _open, tooltip: 'Add contact', child: const Icon(Icons.person_add_alt_1_outlined)),
      body: body,
    );
  }
}
